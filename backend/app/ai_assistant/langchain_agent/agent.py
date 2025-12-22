"""LangChain Agentic AI Agent for Student Talent Analytics.

This module provides a production-ready agentic AI implementation
using LangChain and LangGraph with Google Gemini.
"""

from typing import Dict, Any, List, Optional, Literal
from langchain_google_genai import ChatGoogleGenerativeAI
from langchain_core.messages import (
    BaseMessage, 
    HumanMessage, 
    AIMessage, 
    SystemMessage,
    ToolMessage
)
from langchain_core.runnables import RunnableConfig
from langgraph.graph import StateGraph, START, END, MessagesState
from langgraph.checkpoint.memory import MemorySaver
from langgraph.prebuilt import ToolNode
from sqlalchemy.orm import Session
import logging
import os

from .prompts import CONCISE_SYSTEM_PROMPT
from .tools import get_student_tools, get_all_tools
from .memory import get_session_history, memory_manager

logger = logging.getLogger(__name__)


class StudentTalentAgent:
    """Agentic AI for Student Talent Analytics using LangGraph."""
    
    def __init__(
        self, 
        db: Session,
        api_key: Optional[str] = None,
        model_name: str = "gemini-2.5-flash",
        temperature: float = 0.7,
        include_nlp_tools: bool = True
    ):
        self.db = db
        # Support both GEMINI_API_KEY and GEMINI_API_KEYS (comma-separated)
        self.api_key = api_key or os.getenv("GEMINI_API_KEY")
        if not self.api_key:
            # Try GEMINI_API_KEYS (take first key)
            api_keys = os.getenv("GEMINI_API_KEYS", "")
            if api_keys:
                self.api_key = api_keys.split(",")[0].strip()
        
        self.model_name = model_name
        self.temperature = temperature
        
        if not self.api_key:
            raise ValueError("GEMINI_API_KEY atau GEMINI_API_KEYS tidak ditetapkan!")
        
        # Initialize LLM
        self.llm = ChatGoogleGenerativeAI(
            model=model_name,
            google_api_key=self.api_key,
            temperature=temperature,
            convert_system_message_to_human=True  # Gemini compatibility
        )
        
        # Get tools (with or without NLP)
        if include_nlp_tools:
            self.tools = get_all_tools(db)
        else:
            self.tools = get_student_tools(db)
        
        # Bind tools to LLM
        self.llm_with_tools = self.llm.bind_tools(self.tools)
        
        # Create the agent graph
        self.graph = self._build_graph()
        
        logger.info(f"✅ StudentTalentAgent initialized with {len(self.tools)} tools")
    
    def _build_graph(self) -> StateGraph:
        """Build the LangGraph agent workflow."""
        
        # Define the agent node
        def call_model(state: MessagesState) -> Dict[str, List[BaseMessage]]:
            """Call the LLM with tools bound."""
            messages = state["messages"]
            
            # Prepend system message if not already there
            if not messages or not isinstance(messages[0], SystemMessage):
                messages = [SystemMessage(content=CONCISE_SYSTEM_PROMPT)] + messages
            
            response = self.llm_with_tools.invoke(messages)
            return {"messages": [response]}
        
        # Define routing logic
        def should_continue(state: MessagesState) -> Literal["tools", END]:
            """Decide whether to continue to tools or end."""
            messages = state["messages"]
            last_message = messages[-1]
            
            # If the last message has tool calls, route to tools
            if hasattr(last_message, 'tool_calls') and last_message.tool_calls:
                return "tools"
            
            # Otherwise, end
            return END
        
        # Build the graph
        builder = StateGraph(MessagesState)
        
        # Add nodes
        builder.add_node("agent", call_model)
        builder.add_node("tools", ToolNode(self.tools))
        
        # Add edges
        builder.add_edge(START, "agent")
        builder.add_conditional_edges("agent", should_continue, ["tools", END])
        builder.add_edge("tools", "agent")  # Loop back after tool execution
        
        # Compile with memory checkpointer
        checkpointer = MemorySaver()
        return builder.compile(checkpointer=checkpointer)
    
    async def invoke(
        self, 
        message: str, 
        session_id: str = "default",
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Process a user message through the agent.
        
        Args:
            message: User message
            session_id: Session ID for conversation memory
            config: Additional configuration
            
        Returns:
            Dict with response and metadata
        """
        try:
            # Get session history
            history = get_session_history(session_id)
            
            # Build messages with history
            messages = list(history.messages) + [HumanMessage(content=message)]
            
            # Configure the run
            run_config = RunnableConfig(
                configurable={"thread_id": session_id}
            )
            
            # Invoke the graph
            result = await self.graph.ainvoke(
                {"messages": messages},
                config=run_config
            )
            
            # Extract final response
            final_messages = result.get("messages", [])
            
            # Find the last AI message
            ai_response = None
            tool_calls_made = []
            
            for msg in reversed(final_messages):
                if isinstance(msg, AIMessage):
                    if msg.content and not ai_response:
                        # Handle both string and list content formats
                        content = msg.content
                        if isinstance(content, list):
                            # Extract text from list format (Gemini multimodal response)
                            text_parts = []
                            for part in content:
                                if isinstance(part, dict) and part.get('type') == 'text':
                                    text_parts.append(part.get('text', ''))
                                elif isinstance(part, str):
                                    text_parts.append(part)
                            ai_response = ''.join(text_parts)
                        else:
                            ai_response = str(content)
                    if hasattr(msg, 'tool_calls') and msg.tool_calls:
                        tool_calls_made.extend(msg.tool_calls)
                elif isinstance(msg, ToolMessage):
                    pass  # Track tool results if needed
            
            # Save to history
            history.add_user_message(message)
            if ai_response:
                history.add_ai_message(ai_response)
            
            return {
                "success": True,
                "message": ai_response or "Maaf, saya tidak dapat memproses permintaan anda.",
                "session_id": session_id,
                "tool_calls": [
                    {"name": tc.get("name"), "args": tc.get("args")}
                    for tc in tool_calls_made
                ] if tool_calls_made else [],
                "source": "langchain_agent"
            }
            
        except Exception as e:
            logger.error(f"Error in agent invoke: {e}", exc_info=True)
            return {
                "success": False,
                "message": f"Maaf, berlaku ralat: {str(e)}",
                "session_id": session_id,
                "error": str(e),
                "source": "langchain_agent"
            }
    
    def invoke_sync(
        self, 
        message: str, 
        session_id: str = "default",
        config: Optional[Dict[str, Any]] = None
    ) -> Dict[str, Any]:
        """
        Synchronous version of invoke for non-async contexts.
        
        Args:
            message: User message
            session_id: Session ID for conversation memory
            config: Additional configuration
            
        Returns:
            Dict with response and metadata
        """
        try:
            # Get session history
            history = get_session_history(session_id)
            
            # Build messages with history
            messages = list(history.messages) + [HumanMessage(content=message)]
            
            # Prepend system message
            messages = [SystemMessage(content=CONCISE_SYSTEM_PROMPT)] + messages
            
            # Configure the run
            run_config = RunnableConfig(
                configurable={"thread_id": session_id}
            )
            
            # Invoke the graph synchronously
            result = self.graph.invoke(
                {"messages": messages},
                config=run_config
            )
            
            # Extract final response
            final_messages = result.get("messages", [])
            
            # Find the last AI message with content
            ai_response = None
            tool_calls_made = []
            
            for msg in reversed(final_messages):
                if isinstance(msg, AIMessage):
                    if msg.content and not ai_response:
                        # Handle both string and list content formats
                        content = msg.content
                        if isinstance(content, list):
                            # Extract text from list format (Gemini multimodal response)
                            text_parts = []
                            for part in content:
                                if isinstance(part, dict) and part.get('type') == 'text':
                                    text_parts.append(part.get('text', ''))
                                elif isinstance(part, str):
                                    text_parts.append(part)
                            ai_response = ''.join(text_parts)
                        else:
                            ai_response = str(content)
                    if hasattr(msg, 'tool_calls') and msg.tool_calls:
                        tool_calls_made.extend(msg.tool_calls)
            
            # Save to history
            history.add_user_message(message)
            if ai_response:
                history.add_ai_message(ai_response)
            
            return {
                "success": True,
                "message": ai_response or "Maaf, saya tidak dapat memproses permintaan anda.",
                "session_id": session_id,
                "tool_calls": [
                    {"name": tc.get("name"), "args": tc.get("args")}
                    for tc in tool_calls_made
                ] if tool_calls_made else [],
                "source": "langchain_agent"
            }
            
        except Exception as e:
            logger.error(f"Error in sync agent invoke: {e}", exc_info=True)
            return {
                "success": False,
                "message": f"Maaf, berlaku ralat: {str(e)}",
                "session_id": session_id,
                "error": str(e),
                "source": "langchain_agent"
            }
    
    def clear_session(self, session_id: str) -> None:
        """Clear conversation history for a session."""
        memory_manager.clear_session(session_id)
        logger.info(f"Cleared session: {session_id}")


def create_agent(
    db: Session,
    api_key: Optional[str] = None,
    model_name: str = "gemini-2.5-flash"
) -> StudentTalentAgent:
    """
    Factory function to create a StudentTalentAgent.
    
    Args:
        db: SQLAlchemy database session
        api_key: Gemini API key (optional, uses env var if not provided)
        model_name: Model name to use
        
    Returns:
        Configured StudentTalentAgent instance
    """
    return StudentTalentAgent(
        db=db,
        api_key=api_key,
        model_name=model_name
    )
