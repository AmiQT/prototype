"""AI Assistant package initialization.

Agentic AI System for UTHM Dashboard.
Phase 1: Removed keyword-based actions, Gemini handles all NLU.
Phase 2+: Tool calling, structured context, agentic orchestration.
"""

from .config import get_ai_settings
from .manager import AIAssistantManager
from . import schemas
from .tools import AVAILABLE_TOOLS, get_tool_by_name, get_all_tool_names
from .tool_executor import ToolExecutor

__all__ = [
    "AIAssistantManager",
    "get_ai_settings",
    "schemas",
    "AVAILABLE_TOOLS",
    "get_tool_by_name",
    "get_all_tool_names",
    "ToolExecutor",
]

