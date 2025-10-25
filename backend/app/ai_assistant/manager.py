"""Coordinator for AI assistant commands."""

from __future__ import annotations

import json
import logging
from datetime import date, datetime, timedelta
from typing import Any
from uuid import UUID

from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from . import schemas, logger as ai_logger, permissions
from .config import AISettings, get_ai_settings
# OpenRouter removed - using Gemini only
from .gemini_client import GeminiClient
from .service_bridge import AssistantServiceBridge
from .supabase_bridge import SupabaseAIBridge
from .admin_db_assistant import AdminDatabaseAssistant
# Import our new agentic features
from .plan_generator import PlanGenerator
from .intent_classifier import IntentClassifier
from .clarification_system import ClarificationSystem
from .tool_selector import ToolSelector
from .orchestrator import AgenticOrchestrator
from .conversation_memory import conversation_memory
from .response_variation import DynamicResponseGenerator, ResponseTemplateType
from .template_manager import AdvancedResponseGenerator
from .tools import AVAILABLE_TOOLS
from .tool_executor import ToolExecutor

log = logging.getLogger(__name__)


def serialize_tool_result(obj: Any) -> str:
    """Serialize tool result with proper UUID handling."""
    def json_serializer(obj):
        """Custom JSON serializer for UUID and other non-serializable objects."""
        if isinstance(obj, UUID):
            return str(obj)
        elif isinstance(obj, datetime):
            return obj.isoformat()
        elif isinstance(obj, date):
            return obj.isoformat()
        elif hasattr(obj, '__dict__'):
            return obj.__dict__
        else:
            return str(obj)
    
    try:
        return json.dumps(obj, default=json_serializer, ensure_ascii=False)
    except Exception as e:
        log.error(f"Error serializing tool result: {e}")
        return json.dumps({"error": "Serialization failed", "original_error": str(e)})


class AIAssistantManager:
    """Main entry point for handling AI commands via Gemini API."""

    def __init__(self, settings: AISettings = Depends(get_ai_settings), db: Session = Depends(get_db)) -> None:
        self.settings = settings
        self.daily_usage = 0  # basic in-memory counter (future: persist/cache)
        self._usage_date = date.today()
        self._gemini_client: GeminiClient | None = None
        self._service_bridge = AssistantServiceBridge(db=db)
        self._supabase_bridge = SupabaseAIBridge()
        self._admin_db_assistant = AdminDatabaseAssistant(db=db)
        # Initialize our new agentic features
        self._plan_generator = PlanGenerator()
        self._intent_classifier = IntentClassifier()
        self._clarification_system = ClarificationSystem()
        self._tool_selector = ToolSelector()
        self._agentic_orchestrator = AgenticOrchestrator()
        self._conversation_memory = conversation_memory
        self._dynamic_response_generator = DynamicResponseGenerator()
        self._advanced_response_generator = AdvancedResponseGenerator()
        self._tool_executor = ToolExecutor(self._service_bridge)

    async def handle_command(
        self,
        command: str,
        context: dict[str, Any] | None = None,
        current_user: dict[str, Any] | None = None,
    ) -> schemas.AICommandResponse:
        """Process command using Gemini API (direct agentic mode)."""

        log.info("🤖 AI ASSISTANT: Received command: '%s'", command)
        log.info("🔍 Current user: %s", current_user.get("email") if current_user else "anonymous")
        
        # Extract session information from context
        session_id = context.get("session_id", f"session_{current_user.get('uid', 'anonymous') if current_user else 'anonymous'}") if context else f"session_{current_user.get('uid', 'anonymous') if current_user else 'anonymous'}"
        user_id = current_user.get("uid", "anonymous") if current_user else "anonymous"
        
        # Add user message to conversation memory
        self._conversation_memory.add_user_message(
            user_id=user_id,
            session_id=session_id,
            content=command,
            metadata=context or {}
        )

        self._reset_usage_if_needed()

        if not self.settings.ai_enabled:
            response = schemas.AICommandResponse(
                success=False,
                message="AI assistant is disabled.",
                source=schemas.AISource.MANUAL,
                data={},
            )
            ai_logger.log_ai_action(current_user.get("uid"), command, response.model_dump())
            return response

        if not permissions.can_run_action(current_user or {}, "general"):
            response = schemas.AICommandResponse(
                success=False,
                message="You do not have permission to run AI actions.",
                source=schemas.AISource.MANUAL,
                data={},
                fallback_used=True,
            )
            # Add AI response to conversation memory
            self._conversation_memory.add_ai_response(
                user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                session_id=session_id,
                content="You do not have permission to run AI actions.",
                metadata=response.data or {},
                intent="permission_denied"
            )
            ai_logger.log_ai_action(current_user.get("uid"), command, response.model_dump())
            return response

        # 🚀 ALL COMMANDS NOW ROUTE DIRECTLY TO GEMINI (AGENTIC AI)
        # No local processing, no templates - pure agentic behavior!
        log.info("🤖 Routing ALL commands to Gemini for agentic processing...")

        # Direct ke Gemini bila available
        if self.settings.enable_gemini and self.settings.gemini_api_key:
            # Ensure context has session_id for conversation memory
            context_with_session = context.copy() if context else {}
            context_with_session["session_id"] = session_id
            
            response = await self._call_gemini(command, context_with_session, current_user)
            if response:
                self.daily_usage += 1
                
                # Add AI response to conversation memory with tool usage tracking
                self._conversation_memory.add_ai_response(
                    user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                    session_id=session_id,
                    content=response.message,
                    metadata={
                        **(response.data or {}),
                        "tools_used": response.data.get("tools_used", []) if response.data else [],
                        "iterations": response.data.get("iterations", 0) if response.data else 0,
                        "mode": response.data.get("mode", "conversational") if response.data else "conversational"
                    },
                    intent=response.data.get("intent") if response.data else "gemini_response"
                )
                
                ai_logger.log_ai_action(
                    current_user.get("uid") if current_user else "anonymous",
                    command,
                    response.model_dump(),
                )
                return response

        # If we reach here, no system could handle the request
        raise RuntimeError("No AI system available to handle the request. Gemini API key may not be configured.")

    # 🗑️ REMOVED: Local agentic processing (_handle_agentic_command, _execute_orchestrated_query, etc.)
    # ALL commands now route directly to Gemini for pure agentic AI behavior!
    
    async def _call_gemini(
        self, 
        command: str, 
        context: dict[str, Any] | None,
        current_user: dict[str, Any] | None = None,
    ) -> schemas.AICommandResponse | None:
        """Direct call to Gemini API with agentic tool calling."""
        # Use Gemini only
        use_gemini = self.settings.enable_gemini and self.settings.gemini_api_key
        use_tools = True  # Gemini supports tools

        try:
            system_stats = self._service_bridge.get_system_stats()
            db_status = "available" if not system_stats.get('error') else "maintenance"
        except Exception:
            system_stats = {}
            db_status = "maintenance"
        
        # Build messages with conversation history
        messages = [
            {
                "role": "system",
                "content": f"""You are an agentic AI assistant for the UTHM (Universiti Tun Hussein Onn Malaysia) dashboard system.

CORE IDENTITY:
- You understand and respond naturally in both Bahasa Malaysia and English
- Code-switching (mixing languages) is normal and encouraged
- Match the user's tone, style, and energy
- Be helpful, friendly, and conversational
- Understand context references like "sekalai lagi", "tadi", "sebelum", "that", "again"
- Remember previous actions and build upon them naturally

SYSTEM CONTEXT:
- UTHM dashboard: Student management, events, analytics, profiles
- Database status: {db_status}
- Current users: {system_stats.get('total_users', 'N/A')} total ({system_stats.get('user_breakdown', {}).get('students', 'N/A')} students)

AGENTIC CAPABILITIES:
- You have access to tools that let you query the database in real-time
- When user asks for data (students, events, stats), USE THE TOOLS first to get fresh data
- Don't make up or guess information - call tools to get accurate data
- Combine tool results with your natural language understanding to give great responses

AVAILABLE TOOLS:
- query_students: Search/filter students (by department, CGPA, etc.)
- query_users: Search and filter all users (students, staff, admin) from the UTHM system
- query_profiles: Search and filter user profiles with detailed information (skills, interests, experiences)
- query_events: Get event information and schedules
- query_showcase_posts: Search and filter showcase posts (projects, student work, portfolios)
- query_achievements: Search and filter achievements and awards
- query_event_participations: Search event participations and attendance tracking
- get_system_stats: Get system-wide statistics and overview (with gender analysis)
- query_analytics: Get analytics, trends, and insights (including gender/name analysis)
- analyze_student_names: Advanced NLP analysis of student names for demographics

ADVANCED ADMIN TOOLS:
- advanced_analytics: Perform complex analytics (trends, correlations, performance metrics, engagement analysis, demographic insights, predictive analysis, comparative analysis, anomaly detection)
- cross_entity_query: Analyze relationships between entities (user-event analysis, department performance, skill correlations, engagement patterns, activity analysis, relationship mapping)
- intelligent_search: Semantic search with natural language understanding across all data
- predictive_insights: Generate forecasts and predictions (trend forecasts, behavior predictions, performance predictions, engagement forecasts, growth predictions, risk assessments)
- admin_dashboard_analytics: Generate comprehensive admin dashboards with KPIs, insights, and recommendations

HOW TO RESPOND:
1. **Understand Context**: Read the full conversation history before deciding what to do
2. **Use Tools for Data**: If user asks for info, call appropriate tools FIRST - don't ask for clarification unless absolutely necessary
3. **Answer Naturally**: Present tool results in a conversational, friendly way
4. **Reference History**: When user refers to previous messages ("tadi", "sebelum", "that", "sekalai lagi", etc.), use conversation context
5. **Be Specific**: Use actual data from tools, not made-up examples
6. **Stay Natural**: Don't force keywords or patterns - just have a normal conversation
7. **Context Awareness**: If user says "again" or "sekalai lagi", repeat the last action with same parameters
8. **Proactive Help**: If tools return no results, explain why and suggest alternatives
9. **Take Action**: Don't ask for clarification - make reasonable assumptions and take action
10. **Be Helpful**: Always try to provide useful information even if not exactly what was asked

EXAMPLES:
User: "Pilih 1 student random" → Call query_students with random=true, limit=1
User: "Berapa student dalam sistem?" → Call get_system_stats, present student count naturally
User: "Show me students from Computer Science" → Call query_students with department filter
User: "Berapa student kita pilih tadi?" → Check conversation history, count from context (no tool needed)
User: "How many men and women?" → Call get_system_stats with include_gender_analysis=true
User: "Gender distribution" → Call analyze_student_names with analysis_type=gender_distribution
User: "Naming patterns" → Call analyze_student_names with analysis_type=naming_patterns
User: "sekalai lagi" → Repeat the last tool call with same parameters
User: "Tunjuk event" → Call query_events with upcoming_only=false to show all events
User: "semua event" → Call query_events with upcoming_only=false
User: "event yang akan datang" → Call query_events with upcoming_only=true
User: "Show me all users" → Call query_users to get students, staff, admin
User: "Find profiles with Python skills" → Call query_profiles with skills filter
User: "Show me showcase posts" → Call query_showcase_posts to get student projects
User: "List achievements" → Call query_achievements to get awards and recognition
User: "Who attended event X?" → Call query_event_participations with event_id filter

ADVANCED ADMIN EXAMPLES:
User: "Show me trend analysis for user engagement" → Call advanced_analytics with analysis_type=trend_analysis
User: "Analyze correlation between department and performance" → Call cross_entity_query with query_type=department_performance
User: "Find all high-performing students with Python skills" → Call intelligent_search with semantic search
User: "Predict user growth for next quarter" → Call predictive_insights with prediction_type=growth_prediction
User: "Generate admin dashboard overview" → Call admin_dashboard_analytics with dashboard_type=overview
User: "What are the engagement patterns for FSKTM students?" → Call cross_entity_query with query_type=engagement_patterns
User: "Show me anomaly detection in user activity" → Call advanced_analytics with analysis_type=anomaly_detection
User: "Predict which students might drop out" → Call predictive_insights with prediction_type=risk_assessment

Current time: {datetime.now().isoformat()}"""
            }
        ]
        
        # Get session ID and retrieve structured context
        session_id = context.get("session_id") if context else None
        structured_ctx = None
        
        if session_id:
            # Get structured context (messages + tool calls + insights)
            structured_ctx = self._conversation_memory.get_structured_context(session_id, limit=10)
            
            log.info(f"💬 Session context: {structured_ctx['insights']['message_count']} messages, {structured_ctx['insights']['tool_calls_count']} tools used")
            
            # Add conversation history messages
            for msg_dict in structured_ctx["messages"]:
                if msg_dict["type"] == "user_message":
                    messages.append({
                        "role": "user",
                        "content": msg_dict["content"]
                    })
                elif msg_dict["type"] == "ai_response":
                    messages.append({
                        "role": "assistant",
                        "content": msg_dict["content"]
                    })
            
            # If there are recent tool calls, add context about them
            if structured_ctx["tool_calls"]:
                recent_tools = structured_ctx["tool_calls"][-3:]  # Last 3 tool calls
                tools_summary = "\n".join([
                    f"- {tc['tool']}({tc['result_summary']})" 
                    for tc in recent_tools
                ])
                messages[0]["content"] += f"\n\nRECENT TOOL USAGE IN THIS SESSION:\n{tools_summary}"
                
                # Add last tool call details for "again" context
                if structured_ctx.get("last_tool_call"):
                    last_tool = structured_ctx["last_tool_call"]
                    messages[0]["content"] += f"\n\nLAST TOOL CALL (for 'again'/'sekalai lagi' context):\nTool: {last_tool['tool']}\nArguments: {last_tool.get('arguments', {})}\nResult: {last_tool['result_summary']}\n\nIMPORTANT: If user says 'sekalai lagi', 'again', or similar, repeat this exact tool call with the same arguments!"
        
        # Add current user message
        messages.append({
            "role": "user", 
            "content": command
        })

        try:
            # Initialize Gemini client
            if not self._gemini_client:
                self._gemini_client = GeminiClient(self.settings.gemini_api_key)
            ai_client = self._gemini_client
            ai_source = schemas.AISource.GEMINI
            log.info("🚀 Using Gemini 2.0 Flash (FREE + Tools)")

            # 🚀 AGENTIC LOOP: AI can call tools until it gets final answer
            max_iterations = 5  # Prevent infinite loops
            iteration = 0
            tool_results_data = []
            
            while iteration < max_iterations:
                iteration += 1
                log.info(f"🔄 Agentic loop iteration {iteration}/{max_iterations}")
                
                response = await ai_client.chat_completion(
                    messages=messages,
                    max_tokens=800,
                    temperature=0.7,
                    tools=AVAILABLE_TOOLS if use_tools else None
                )
                
                # Check if response is text or tool_calls
                if isinstance(response, str):
                    # Final text response - we're done!
                    log.info(f"✅ Got final text response from Gemini")
                    return schemas.AICommandResponse(
                        success=True,
                        message=response,
                        source=ai_source,
                        data={
                            "model": "gemini-2.0-flash-exp",
                            "mode": "agentic",
                            "database_status": db_status,
                            "iterations": iteration,
                            "tools_used": tool_results_data
                        },
                    )
                
                # AI wants to call tools!
                elif isinstance(response, dict) and response.get("type") == "tool_calls":
                    log.info(f"🔧 AI requested {len(response['tool_calls'])} tool calls")
                    
                    # Add AI's message (with tool calls) to conversation
                    messages.append(response["message"])
                    
                    # Execute each tool call
                    for tool_call in response["tool_calls"]:
                        tool_name = tool_call["function"]["name"]
                        tool_args = json.loads(tool_call["function"]["arguments"])
                        tool_id = tool_call["id"]
                        
                        log.info(f"⚙️ Executing tool: {tool_name} with args: {tool_args}")
                        
                        # Execute the tool
                        tool_result = await self._tool_executor.execute_tool(tool_name, tool_args)
                        
                        log.info(f"✅ Tool {tool_name} result: {tool_result.get('success', False)}")
                        
                        # Track tool usage
                        tool_results_data.append({
                            "tool": tool_name,
                            "arguments": tool_args,
                            "result": tool_result
                        })
                        
                        # Add tool call to conversation memory
                        self._conversation_memory.add_tool_call(
                            current_user.get("uid") if current_user else "anonymous",
                            session_id,
                            tool_name,
                            tool_args,
                            tool_result,
                            success=tool_result.get("success", True)
                        )
                        
                        # Add tool result to messages for next iteration
                        messages.append({
                            "role": "tool",
                            "tool_call_id": tool_id,
                            "name": tool_name,
                            "content": serialize_tool_result(tool_result)
                        })
                    
                    # Continue loop - Gemini will process tool results
                    log.info("🔄 Tools executed, continuing agentic loop...")
                    continue
                
                else:
                    # Unexpected response format
                    log.error(f"Unexpected response format: {response}")
                    raise RuntimeError(f"Unexpected AI response: {response}")
            
            # Max iterations reached
            log.warning(f"⚠️ Max iterations ({max_iterations}) reached")
            return schemas.AICommandResponse(
                success=True,
                message="Maaf, saya perlu terlalu banyak steps untuk selesaikan task ni. Cuba simplify request awak? 🙏",
                source=ai_source,
                data={
                            "model": "gemini-2.0-flash-exp",
                    "mode": "agentic",
                    "database_status": db_status,
                    "iterations": iteration,
                    "tools_used": tool_results_data,
                    "max_iterations_reached": True
                },
            )

        except Exception as e:
            log.error(f"Gemini error: {e}")
            # Re-raise the exception so user can see actual errors
            raise

    def _attach_quota(self, response: schemas.AICommandResponse) -> schemas.AICommandResponse:
        """Attach quota information to response."""
        response.data = response.data or {}
        response.data["quota"] = {
            "daily_usage": self.daily_usage,
            "daily_limit": 1000,  # Gemini has generous limits
            "usage_date": self._usage_date.isoformat(),
        }
        return response

    def _reset_usage_if_needed(self) -> None:
        """Reset usage counter if we've moved to a new day."""
        today = date.today()
        if today != self._usage_date:
            self.daily_usage = 0
            self._usage_date = today
