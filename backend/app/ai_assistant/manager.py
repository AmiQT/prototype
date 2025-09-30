"""Coordinator for AI assistant commands."""

from __future__ import annotations

import json
import logging
from datetime import date, datetime, timedelta
from typing import Any

from fastapi import Depends
from sqlalchemy.orm import Session

from app.database import get_db
from . import schemas, logger as ai_logger, permissions
from .config import AISettings, get_ai_settings
from .openrouter_client import OpenRouterClient
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

log = logging.getLogger(__name__)


class AIAssistantManager:
    """Main entry point for handling AI commands via OpenRouter."""

    def __init__(self, settings: AISettings = Depends(get_ai_settings), db: Session = Depends(get_db)) -> None:
        self.settings = settings
        self.daily_usage = 0  # basic in-memory counter (future: persist/cache)
        self._usage_date = date.today()
        self._openrouter_client: OpenRouterClient | None = None
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

    async def handle_command(
        self,
        command: str,
        context: dict[str, Any] | None = None,
        current_user: dict[str, Any] | None = None,
    ) -> schemas.AICommandResponse:
        """Process command using OpenRouter (direct agentic mode)."""

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

        # Try to handle with local agentic actions first (database queries)
        log.info("🔧 Trying local agentic actions first...")
        local_response = await self._try_local_agentic_action(command, current_user)
        if local_response:
            log.info("✅ Local agentic action handled the command successfully!")
            
            # Add AI response to conversation memory
            self._conversation_memory.add_ai_response(
                user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                session_id=session_id,
                content=local_response.message,
                metadata=local_response.data or {},
                intent=local_response.data.get("intent") if local_response.data else "local_action"
            )
            
            ai_logger.log_ai_action(
                current_user.get("uid") if current_user else "anonymous",
                command,
                local_response.model_dump(),
            )
            return local_response
        else:
            log.info("❌ No local agentic action found, proceeding to OpenRouter...")

        # ADMIN DATABASE ASSISTANT - Clean implementation!
        admin_db_response = await self._admin_db_assistant.handle_admin_query(command, current_user)
        if admin_db_response:
            # Add AI response to conversation memory
            self._conversation_memory.add_ai_response(
                user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                session_id=session_id,
                content=admin_db_response.message,
                metadata=admin_db_response.data or {},
                intent=admin_db_response.data.get("intent") if admin_db_response.data else "admin_db_query"
            )
            return admin_db_response

        # NEW: AGENTIC AI PROCESSING
        agentic_response = await self._handle_agentic_command(command, context, current_user)
        if agentic_response:
            # Add AI response to conversation memory
            self._conversation_memory.add_ai_response(
                user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                session_id=session_id,
                content=agentic_response.message,
                metadata=agentic_response.data or {},
                intent=agentic_response.data.get("intent") if agentic_response.data else "agentic_response"
            )
            
            ai_logger.log_ai_action(
                current_user.get("uid") if current_user else "anonymous",
                command,
                agentic_response.model_dump(),
            )
            return agentic_response

        # Direct ke OpenRouter bila available
        if self.settings.enable_openrouter and self.settings.openrouter_api_key:
            if self.daily_usage >= self.settings.openrouter_daily_limit:
                log.warning("OpenRouter quota reached for the day")

            response = await self._call_openrouter(command, context)
            if response:
                self.daily_usage += 1
                
                # Add AI response to conversation memory
                self._conversation_memory.add_ai_response(
                    user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                    session_id=session_id,
                    content=response.message,
                    metadata=response.data or {},
                    intent=response.data.get("intent") if response.data else "openrouter_response"
                )
                
                ai_logger.log_ai_action(
                    current_user.get("uid") if current_user else "anonymous",
                    command,
                    response.model_dump(),
                )
                return response

        log.info("Rate limit reached, will use casual fallback response")

        # NEW: Agentic command handling as fallback when OpenRouter is not available
        agentic_fallback_response = await self._handle_agentic_command(command, context, current_user, use_fallback=True)
        if agentic_fallback_response:
            # Add AI response to conversation memory
            self._conversation_memory.add_ai_response(
                user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
                session_id=session_id,
                content=agentic_fallback_response.message,
                metadata=agentic_fallback_response.data or {},
                intent=agentic_fallback_response.data.get("intent") if agentic_fallback_response.data else "agentic_fallback"
            )
            
            ai_logger.log_ai_action(
                current_user.get("uid") if current_user else "anonymous",
                command,
                agentic_fallback_response.model_dump(),
            )
            return agentic_fallback_response

        # Enhanced fallback responses with greeting detection
        command_lower = command.lower().strip()
        
        # Greetings
        if any(word in command_lower for word in ["hai", "hello", "hi", "hey", "helo"]):
            casual_msg = self._dynamic_response_generator.generate_greeting({"user_name": current_user.get("name", "Admin") if current_user else "Admin"}, session_id)
        # Identity questions
        elif any(word in command_lower for word in ["siapa", "nama", "who are you", "what are you"]):
            casual_msg = "Saya AI Assistant untuk UTHM dashboard! 🤖 Saya boleh bantu awak dengan:\n\n✅ Query student data\n✅ System statistics\n✅ Event management\n✅ Analytics & reports\n\nApa yang awak nak tahu? 😊"
        # Status check
        elif "apa khabar" in command_lower or "how are you" in command_lower:
            casual_msg = self._dynamic_response_generator.generate_greeting({"user_name": current_user.get("name", "Admin") if current_user else "Admin"}, session_id)
        # Help requests
        elif any(word in command_lower for word in ["help", "tolong", "bantuan", "assist"]):
            casual_msg = "Sure! 💡 Saya boleh bantu dengan:\n\n**📊 Data Queries:**\n• Berapa jumlah pelajar?\n• List students\n• Show system overview\n\n**🎲 Random Selection:**\n• Pilih 1 random student\n\n**📈 Analytics:**\n• System statistics\n• Performance metrics\n\nCuba tanya je, saya akan respond! 😊"
        # Thanks
        elif any(word in command_lower for word in ["terima kasih", "thanks", "thank you", "tq", "tqvm"]):
            casual_msg = "Sama-sama! 😊 Happy to help! Ada lagi yang awak nak tanya?"
        # Goodbye
        elif any(word in command_lower for word in ["bye", "selamat tinggal", "goodbye"]):
            casual_msg = self._dynamic_response_generator.generate_for_intent('goodbye', session_id=session_id)
        # UTHM knowledge questions
        elif any(word in command_lower for word in ["uthm", "universiti", "university", "kampus"]) and any(word in command_lower for word in ["apa", "what", "tahu", "know", "pasal", "about"]):
            casual_msg = "🎓 **UTHM (Universiti Tun Hussein Onn Malaysia)** ni adalah universiti teknikal yang terletak di Johor!\n\n✨ **Dalam sistem ni:**\n• Total **7 students** registered\n• Multiple departments (FSKTM, Engineering, etc)\n• Active talent profiling system\n\nNak tahu lebih details? Try:\n• 'Show me system overview'\n• 'List all students'\n• 'Berapa jumlah pelajar?' 😊"
        # Generic fallback
        else:
            casual_msg = "Hmm, saya tak pasti apa yang awak maksudkan. 🤔\n\nCuba tanya soalan yang lebih specific macam:\n• **Berapa jumlah pelajar?**\n• **List students**\n• **System overview**\n• **Pilih random student**\n\nAtau type **'help'** untuk list commands! 😊"

        response = schemas.AICommandResponse(
            success=True,  # Make it success so UI shows friendly message
            message=casual_msg,
            source=schemas.AISource.OPENROUTER,
            data={"status": "quota_reached", "mode": "casual_fallback"},
            fallback_used=True,
        )
        response = self._attach_quota(response)
        
        # Add AI response to conversation memory
        self._conversation_memory.add_ai_response(
            user_id=current_user.get("uid", "anonymous") if current_user else "anonymous",
            session_id=session_id,
            content=casual_msg,
            metadata=response.data or {},
            intent="fallback_response"
        )
        
        ai_logger.log_ai_action(current_user.get("uid") if current_user else "anonymous", command, response.model_dump())
        return response

    async def _handle_agentic_command(
        self, 
        command: str, 
        context: dict[str, Any] | None = None, 
        current_user: dict[str, Any] | None = None,
        use_fallback: bool = False
    ) -> schemas.AICommandResponse | None:
        """Handle command using our new agentic AI features via orchestrator."""
        log.info(f"🤖 AGENTIC AI: Processing command: '{command}'")
        
        try:
            # Use the orchestrator to process the command through all components
            orchestration_result = await self._agentic_orchestrator.process_command(command, context)
            
            # If clarification is needed, return clarification message
            if orchestration_result.get("needs_clarification"):
                clarification_details = orchestration_result["clarification_response"]
                clarification_message = "Wah, sorry lah! Saya perlukan sedikit maklumat tambahan untuk bantu awak:\\n\\n"
                
                for question in clarification_details["questions"]:
                    clarification_message += f"❓ {question}\\n"
                for suggestion in clarification_details["suggestions"]:
                    clarification_message += f"💡 {suggestion}\\n\\n"
                
                clarification_message += "Boleh tolong bagi maklumat yang lebih spesifik tak? Tqvm!"
                
                return schemas.AICommandResponse(
                    success=True,
                    message=clarification_message,
                    source=schemas.AISource.ENHANCED_SUPABASE,
                    data=orchestration_result,
                    steps=[schemas.AICommandStep(label="🔍 Clarification Needed", detail="Requesting more specific information")]
                )
            
            # If we have a well-defined intent and plan, execute it
            intent = orchestration_result["intent"]
            entities = orchestration_result["entities"]
            plan_steps = orchestration_result["plan_steps"]
            confidence = orchestration_result.get("confidence", 0)
            
            # Skip execution if confidence is too low (likely misclassified)
            if confidence < 0.3:
                log.info(f"⚠️ Low confidence ({confidence}), skipping orchestrated execution")
                return None
            
            # Execute queries based on intent
            result = None
            if intent in ["student_query", "event_query", "analytics_query"]:
                result = await self._execute_orchestrated_query(intent, entities)
            elif intent == "multi_intent":
                result = await self._execute_multi_step_query(orchestration_result)
            
            if result:
                # Format the result appropriately
                formatted_message = self._format_orchestrated_result(result, intent, entities)
                
                return schemas.AICommandResponse(
                    success=True,
                    message=formatted_message,
                    source=schemas.AISource.ENHANCED_SUPABASE,
                    data=orchestration_result | {"query_result": result},
                    steps=[
                        schemas.AICommandStep(label="🚀 Agentic Processing", detail=f"Executed {len(plan_steps)}-step plan"),
                        *[schemas.AICommandStep(label=f"Step {i+1}", detail=step["description"]) for i, step in enumerate(plan_steps)]
                    ]
                )
            
            # If no specific query was executed but we have plan steps, explain the plan
            if len(plan_steps) > 0:
                plan_explanation = f"Wah bestnya! 🎉 Saya faham apa awak nak buat. Berdasarkan permintaan awak '{command}', saya buat plan macam ni:\\n\\n"
                for i, step in enumerate(plan_steps, 1):
                    plan_explanation += f"{i}. {step['description']}\\n"
                
                plan_explanation += "\\nSure lah! Saya dah siapkan plan untuk proses permintaan awak. Tqvm!"
                
                return schemas.AICommandResponse(
                    success=True,
                    message=plan_explanation,
                    source=schemas.AISource.ENHANCED_SUPABASE,
                    data=orchestration_result,
                    steps=[
                        schemas.AICommandStep(label="🚀 Plan Generated", detail=f"Created {len(plan_steps)}-step plan"),
                        *[schemas.AICommandStep(label=f"Step {i+1}", detail=step['description']) for i, step in enumerate(plan_steps)]
                    ]
                )

        except Exception as e:
            log.error(f"Error in agentic command processing: {e}")
            if not use_fallback:
                # Try to handle with basic local agentic action as final fallback
                local_response = await self._try_local_agentic_action(command, current_user)
                if local_response:
                    return local_response

        return None

    async def _execute_orchestrated_query(
        self,
        intent: str,
        entities: dict[str, Any]
    ) -> dict[str, Any] | list | None:
        """Execute query based on orchestrated intent and entities."""
        try:
            if intent == "student_query":
                criteria = {}
                if 'departments' in entities and entities['departments']:
                    criteria["department"] = entities['departments'][0]
                if 'min_cgpa' in entities:
                    criteria["cgpa_min"] = entities['min_cgpa']
                if 'numbers' in entities and entities['numbers']:
                    criteria["limit"] = entities['numbers'][0]
                else:
                    criteria["limit"] = 10
                
                return self._service_bridge.search_students_by_criteria(criteria)
            
            elif intent == "event_query":
                criteria = {"limit": entities.get('numbers', [10])[0] if 'numbers' in entities else 10}
                return self._service_bridge._search_events_advanced(criteria)
            
            elif intent == "analytics_query":
                return self._service_bridge._search_analytics({"type": "department_performance"})
        
        except Exception as e:
            log.error(f"Error executing orchestrated query: {e}")
            return None

    async def _execute_multi_step_query(self, orchestration_result: dict) -> dict[str, Any] | None:
        """Execute multi-step query based on orchestration result."""
        try:
            results = []
            plan_steps = orchestration_result["plan_steps"]
            entities = orchestration_result["entities"]
            
            for step in plan_steps:
                step_result = await self._execute_orchestrated_query(step["task_type"], entities)
                results.append({
                    "step_description": step["description"],
                    "result": step_result
                })
            
            return {
                "multi_step_results": results,
                "summary": f"Completed {len(results)} steps in multi-step query"
            }
        
        except Exception as e:
            log.error(f"Error executing multi-step query: {e}")
            return None

    def _format_orchestrated_result(
        self, 
        result: dict[str, Any] | list, 
        intent: str, 
        entities: dict[str, Any]
    ) -> str:
        """Format the result from orchestrated processing into a user-friendly message."""
        if not result:
            return "Wah sorry lah! Saya tak jumpa maklumat yang awak cari. Boleh cuba permintaan yang lain tak?"
        
        # Format based on intent type
        if intent == "student_query":
            if isinstance(result, list) and len(result) > 0:
                count = len(result)
                message = f"Wah bestnya! 🎉 Saya jumpa **{count} students** mengikut permintaan awak!\\n\\n"
                
                for i, student in enumerate(result[:5], 1):  # Show first 5
                    message += f"{i}. **{student.get('name', 'N/A')}\\n"
                    message += f"   📧 Email: {student.get('email', 'N/A')}\\n"
                    message += f"   🏢 Department: {student.get('department', 'N/A')}\\n"
                    if student.get('cgpa'):
                        message += f"   📊 CGPA: {student.get('cgpa')}\\n"
                    message += "\\n"
                
                if len(result) > 5:
                    message += f"... dan {len(result) - 5} lagi! Tqvm sebab tunggu. 😊"
                
                return message
            else:
                return "Hmm, sorry lah! Saya tak jumpa students yang sesuai dengan kriteria awak. Boleh cuba adjust sikit search criteria awak?"
        
        elif intent == "event_query":
            if isinstance(result, list) and len(result) > 0:
                count = len(result)
                message = f"Jumpa **{count} events** untuk awak! Ni detailsnya: 📅\\n\\n"
                
                for i, event in enumerate(result[:5], 1):
                    message += f"{i}. **{event.get('title', 'N/A')}\\n"
                    message += f"   📅 Date: {event.get('event_date', 'N/A')}\\n"
                    message += f"   📍 Location: {event.get('location', 'N/A')}\\n\\n"
                
                if len(result) > 5:
                    message += f"... dan {len(result) - 5} events lagi! 😊"
                
                return message
            else:
                return "Hmm, sorry lah! Saya tak jumpa events yang sesuai. Boleh cuba dengan tarikh atau jenis event yang lain?"
        
        elif intent == "multi_intent":
            if isinstance(result, dict) and 'multi_step_results' in result:
                message = "Wah bestnya! 🎉 Saya dah complete kan multi-step request awak:\\n\\n"
                
                for i, step_result in enumerate(result['multi_step_results'], 1):
                    message += f"Step {i}: {step_result['step_description']}\\n"
                    if step_result['result']:
                        count = len(step_result['result']) if isinstance(step_result['result'], list) else 1
                        message += f"   → Jumpa {count} results\\n"
                    else:
                        message += "   → Tak dapat results\\n"
                    message += "\\n"
                
                return message + "Semua steps dah siap! Tqvm sudi tunggu. 😊"
        
        # Default formatting
        if isinstance(result, list):
            return f"Wah bestnya! Saya jumpa {len(result)} results untuk awak. Ada {len(result)} items dalam response ni. Tqvm! 🎉"
        elif isinstance(result, dict):
            return f"Wah bestnya! Saya proses permintaan awak dan dapatkan results. Tqvm! 🎉"
        else:
            return "Wah bestnya! Saya dah proses permintaan awak. Tqvm! 🎉"

    async def _try_local_agentic_action(
        self,
        command: str,
        current_user: dict[str, Any] | None,
    ) -> schemas.AICommandResponse | None:
        """Try to handle command with local agentic actions using real data."""
        
        command_lower = command.lower()
        
        # Random student selection queries
        if any(keyword in command_lower for keyword in ["pilih", "select", "random", "pick", "tunjuk"]) and any(keyword in command_lower for keyword in ["pelajar", "student", "nama"]):
            log.info("🎯 DETECTED: Random student selection query!")
            try:
                import random
                students = self._service_bridge.search_students_by_criteria({"limit": 100})
                if students and len(students) > 0:
                    selected = random.choice(students)
                    
                    message = f"Okay! Saya pilih secara random: **{selected['name']}** 🎲\n\n"
                    message += f"📧 **Email:** {selected['email']}\n"
                    if selected.get('department'):
                        message += f"🏢 **Department:** {selected['department']}\n"
                    if selected.get('student_id'):
                        message += f"🎓 **Student ID:** {selected['student_id']}\n"
                    if selected.get('cgpa'):
                        message += f"📊 **CGPA:** {selected['cgpa']}\n"
                    
                    message += f"\n✨ Ni lah student yang saya pilih untuk awak! 😊"
                    
                    return schemas.AICommandResponse(
                        success=True,
                        message=message,
                        source=schemas.AISource.OPENROUTER,
                        data={
                            "selected_student": selected,
                            "total_pool": len(students),
                            "conversational_response": True
                        },
                        steps=[schemas.AICommandStep(label="Random Selection", detail=f"Selected 1 from {len(students)} students")]
                    )
                else:
                    return schemas.AICommandResponse(
                        success=True,
                        message="Hmm, tak jumpa students dalam sistem. Mungkin database masih kosong? 🤔",
                        source=schemas.AISource.OPENROUTER,
                        data={"error": "no_students_found"},
                        steps=[schemas.AICommandStep(label="Query", detail="No students found in database")]
                    )
            except Exception as e:
                log.error(f"Error in random student selection: {e}")
                return None
        
        # Student count queries - Conversational responses (using actual data)
        if any(keyword in command_lower for keyword in ["berapa", "jumlah", "count", "total"]) and any(keyword in command_lower for keyword in ["pelajar", "student", "mahasiswa"]):
            log.info("🎯 DETECTED: Student count query!")
            try:
                stats = self._service_bridge.get_system_stats()
                student_count = stats.get('user_breakdown', {}).get('students', 0)
                
                # Responses based on actual data
                if "fsktm" in command_lower or "computer science" in command_lower:
                    message = f"📊 Currently there are **{student_count} students** registered in the system overall.\n\n"
                    message += f"💡 For specific FSKTM/Computer Science data, I'd recommend querying more specific information!"
                else:
                    message = f"📊 Based on latest data, the UTHM system has **{student_count} active students**.\n\n"
                    message += f"👥 **Total users** (including lecturers and admins): **{stats.get('total_users', 0)}**"
                
                return schemas.AICommandResponse(
                    success=True,
                    message=message,
                    source=schemas.AISource.OPENROUTER,
                    data={
                        "student_count": student_count,
                        "total_users": stats.get('total_users', 0),
                        "profile_completion_rate": stats.get('profile_completion_rate', 0),
                        "activity_stats": stats.get('activity_stats', {}),
                        "conversational_response": True
                    },
                    steps=[schemas.AICommandStep(label="Database Query", detail="Retrieved live student data")]
                )
            except Exception as e:
                log.error(f"Error getting student count: {e}")
                return None

        # List students queries
        if any(keyword in command_lower for keyword in ["list", "senarai", "tunjuk", "show"]) and any(keyword in command_lower for keyword in ["pelajar", "student", "students"]):
            log.info("🎯 DETECTED: List students query!")
            try:
                limit = 10  # Default
                # Extract limit from command if present
                import re
                numbers = re.findall(r'\d+', command)
                if numbers:
                    limit = min(int(numbers[0]), 50)  # Max 50
                
                students = self._service_bridge.search_students_by_criteria({"limit": limit})
                if students and len(students) > 0:
                    message = f"Wah bestnya! 🎉 Ni senarai **{len(students)} students** dalam sistem:\n\n"
                    
                    for i, student in enumerate(students[:limit], 1):
                        message += f"**{i}. {student['name']}**\n"
                        message += f"   📧 {student['email']}\n"
                        if student.get('department'):
                            message += f"   🏢 {student['department']}\n"
                        if student.get('student_id'):
                            message += f"   🎓 ID: {student['student_id']}\n"
                        message += "\n"
                    
                    message += f"✨ **Total:** {len(students)} students ditunjukkan! 😊"
                    
                    return schemas.AICommandResponse(
                        success=True,
                        message=message,
                        source=schemas.AISource.OPENROUTER,
                        data={
                            "students": students,
                            "count": len(students),
                            "conversational_response": True
                        },
                        steps=[schemas.AICommandStep(label="Database Query", detail=f"Retrieved {len(students)} students")]
                    )
                else:
                    return schemas.AICommandResponse(
                        success=True,
                        message="Hmm, tak jumpa students dalam sistem. Database masih kosong ke? 🤔",
                        source=schemas.AISource.OPENROUTER,
                        data={"error": "no_students_found"},
                        steps=[schemas.AICommandStep(label="Query", detail="No students found")]
                    )
            except Exception as e:
                log.error(f"Error listing students: {e}")
                return None
        
        # System overview queries - Using actual data!
        if any(keyword in command_lower for keyword in ["sistem", "system", "overview", "ringkasan", "dashboard"]):
            try:
                stats = self._service_bridge.get_system_stats()
                
                students = stats.get('user_breakdown', {}).get('students', 0)
                lecturers = stats.get('user_breakdown', {}).get('lecturers', 0)
                admins = stats.get('user_breakdown', {}).get('admins', 0)
                events = stats.get('activity_stats', {}).get('events', 0)
                total = stats.get('total_users', 0)
                completion = stats.get('profile_completion_rate', 0)
                
                message = f"📊 **System Overview**\n\n"
                message += f"👥 **Total Users:** {total}\n"
                message += f"   • **Students:** {students}\n"
                message += f"   • **Lecturers:** {lecturers}\n" 
                message += f"   • **Admins:** {admins}\n\n"
                message += f"📅 **Events Scheduled:** {events}\n"
                message += f"✅ **Profile Completion:** {completion}%\n\n"
                message += f"✨ This shows all users are engaged with the platform!"
                
                return schemas.AICommandResponse(
                    success=True,
                    message=message,
                    source=schemas.AISource.OPENROUTER,
                    data=stats,
                    steps=[schemas.AICommandStep(label="System Overview", detail="Retrieved comprehensive system statistics")]
                )
            except Exception as e:
                log.error(f"Error getting system overview: {e}")
                return None

        return None  # No local action found

    

    async def _call_openrouter(
        self,
        command: str,
        context: dict[str, Any] | None,
    ) -> schemas.AICommandResponse | None:
        if not self._openrouter_client:
            return None

        model = "qwen/qwen3-30b-a3b:free"

        try:
            system_stats = self._service_bridge.get_system_stats()
            db_status = "available" if not system_stats.get('error') else "maintenance"
        except Exception:
            system_stats = {}
            db_status = "maintenance"
        
        messages = [
            {
                "role": "system",
                "content": f"""You are a friendly AI assistant for UTHM (Universiti Tun Hussein Onn Malaysia) dashboard in Malaysia. 

PERSONALITY & TONE:
- Be conversational, friendly, and use Gen Z tone
- Mix English and Bahasa Malaysia naturally (like Malaysian Gen Z, e.g., "Sure lah!", "Wah bestnya!", "Tqvm!")
- Use emojis appropriately but don't overdo
- Be helpful but not overly formal
- Sound like a knowledgeable student buddy helping out
- Be encouraging and positive, use phrases like "Wah bestnya!", "Tqvm!", "Sure lah!", "No prob!"

CONTEXT:
- You help with UTHM dashboard system queries and general assistance
- Database status: {db_status}
- System has {system_stats.get('total_users', 'some')} users ({system_stats.get('user_breakdown', {}).get('students', 'several')} students)
- Current time: {datetime.now().isoformat()}

ENHANCED CAPABILITIES:
- You can understand and execute complex natural language queries
- You can query real-time data from the system
- You can provide detailed analytics and insights
- You can search for specific users, events, or profiles
- You can generate reports and summaries

IMPORTANT:
- Always respond naturally, like you're chatting with a friend
- Never mention technical limitations, API quotas, or error codes
- If database is in "maintenance", just say you'll help with general info instead
- Focus on being helpful and conversational
- Use local Malaysian expressions and slang naturally
- Be encouraging and supportive

Respond in a natural, helpful, and very human-like way to: {command}"""
            },
            {
                "role": "user", 
                "content": command
            }
        ]

        try:
            if not self._openrouter_client:
                self._openrouter_client = OpenRouterClient(api_key=self.settings.openrouter_api_key)

            response_text = await self._openrouter_client.chat_completion(
                model=model,
                messages=messages,
                max_tokens=800,
                temperature=0.7
            )

            return schemas.AICommandResponse(
                success=True,
                message=response_text,
                source=schemas.AISource.OPENROUTER,
                data={
                    "model": model,
                    "mode": "conversational",
                    "database_status": db_status
                },
            )

        except Exception as e:
            log.error(f"OpenRouter error: {e}")
            return None

    def _attach_quota(self, response: schemas.AICommandResponse) -> schemas.AICommandResponse:
        """Attach quota information to response."""
        response.data = response.data or {}
        response.data["quota"] = {
            "daily_usage": self.daily_usage,
            "daily_limit": self.settings.openrouter_daily_limit,
            "usage_date": self._usage_date.isoformat(),
        }
        return response

    def _reset_usage_if_needed(self) -> None:
        """Reset usage counter if we've moved to a new day."""
        today = date.today()
        if today != self._usage_date:
            self.daily_usage = 0
            self._usage_date = today