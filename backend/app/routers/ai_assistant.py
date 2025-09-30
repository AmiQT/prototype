"""FastAPI router untuk AI assistant command endpoint."""

from fastapi import APIRouter, Depends, HTTPException, status
from typing import Optional

from app.auth import verify_supabase_token

from app.ai_assistant.manager import AIAssistantManager
from app.ai_assistant import schemas, history
from app.ai_assistant.conversation_memory import conversation_memory, MemoryType
from app.ai_assistant.response_variation import response_variation_system
from app.ai_assistant.template_manager import template_manager

router = APIRouter(prefix="/api/ai", tags=["ai-assistant"])


@router.post("/command", response_model=schemas.AICommandResponse)
async def process_ai_command(
    payload: schemas.AICommandRequest,
    manager: AIAssistantManager = Depends(),
    current_user: dict = Depends(verify_supabase_token),
):
    """Process command yang datang dari web dashboard."""

    if not payload.command.strip():
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Command cannot be empty")

    # Log the incoming command for debugging
    print(f"🤖 AI Assistant received command: {payload.command}")

    # Extract session ID from context or generate new one
    session_id = payload.context.get("session_id", f"session_{current_user.get('uid', 'anonymous')}")
    
    # Add user message to conversation memory
    conversation_memory.add_user_message(
        user_id=current_user.get("uid", "anonymous"),
        session_id=session_id,
        content=payload.command,
        metadata=payload.context
    )

    response = await manager.handle_command(
        payload.command,
        context=payload.context,
        current_user=current_user,
    )

    # Add AI response to conversation memory
    if response.success and response.message:
        conversation_memory.add_ai_response(
            user_id=current_user.get("uid", "anonymous"),
            session_id=session_id,
            content=response.message,
            metadata=response.data or {},
            intent=response.data.get("intent") if response.data else None
        )

    # Log the response for debugging
    print(f"🤖 AI Assistant response success: {response.success}, message length: {len(response.message)}")

    if not response.success:
        # 200 OK tapi kita embed success flag → frontend boleh handle gracefully
        # Option: kalau nak 4xx, boleh tukar bila behaviour dah stabil.
        return response

    return response


@router.get("/history")
async def get_ai_history(limit: int = 10):
    return {
        "history": history.get_recent_history(limit),
    }


# New endpoints for conversation memory management
@router.get("/conversations")
async def get_user_conversations(
    current_user: dict = Depends(verify_supabase_token),
    session_limit: int = 10,
    message_limit: int = 20
):
    """Get user's conversation history."""
    user_id = current_user.get("uid", "anonymous")
    history = conversation_memory.get_user_conversation_history(
        user_id, session_limit, message_limit
    )
    
    return {
        "user_id": user_id,
        "conversations": {
            session_id: [
                {
                    "id": msg.id,
                    "content": msg.content,
                    "type": msg.message_type.value,
                    "timestamp": msg.timestamp.isoformat(),
                    "metadata": msg.metadata
                } for msg in messages
            ]
            for session_id, messages in history.items()
        }
    }


@router.get("/conversation/{session_id}")
async def get_conversation_session(
    session_id: str,
    limit: int = 50,
    current_user: dict = Depends(verify_supabase_token)
):
    """Get specific conversation session history."""
    # Verify user has access to this session (basic check)
    user_sessions = conversation_memory.get_user_sessions(current_user.get("uid", "anonymous"))
    if session_id not in user_sessions and current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this conversation session"
        )
    
    messages = conversation_memory.get_conversation_history(session_id, limit)
    
    return {
        "session_id": session_id,
        "messages": [
            {
                "id": msg.id,
                "content": msg.content,
                "type": msg.message_type.value,
                "timestamp": msg.timestamp.isoformat(),
                "metadata": msg.metadata
            } for msg in messages
        ],
        "summary": conversation_memory.get_session_summary(session_id)
    }


@router.delete("/conversation/{session_id}")
async def clear_conversation_session(
    session_id: str,
    current_user: dict = Depends(verify_supabase_token)
):
    """Clear specific conversation session."""
    # Verify user has access to this session
    user_sessions = conversation_memory.get_user_sessions(current_user.get("uid", "anonymous"))
    if session_id not in user_sessions and current_user.get("role") != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this conversation session"
        )
    
    success = conversation_memory.clear_session(session_id)
    
    if success:
        return {"message": f"Session {session_id} cleared successfully", "success": True}
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Session {session_id} not found"
        )


@router.delete("/conversations")
async def clear_user_conversations(
    current_user: dict = Depends(verify_supabase_token)
):
    """Clear all conversation sessions for user."""
    user_id = current_user.get("uid", "anonymous")
    success = conversation_memory.clear_user_sessions(user_id)
    
    if success:
        return {"message": f"All sessions for user {user_id} cleared successfully", "success": True}
    else:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"No sessions found for user {user_id}"
        )


@router.get("/templates")
async def get_templates(
    category: Optional[str] = None,
    tag: Optional[str] = None,
    search: Optional[str] = None
):
    """Get available templates."""
    templates = []
    
    if search:
        # Search templates
        found_templates = template_manager.search_templates(search)
        templates = [
            {
                "template_id": t.template_id,
                "name": t.name,
                "content": t.content,
                "category": t.category.value,
                "tags": t.tags,
                "variables": t.variables,
                "priority": t.priority,
                "is_active": t.is_active
            } for t in found_templates
        ]
    elif tag:
        # Get templates by tag
        found_templates = template_manager.get_templates_by_tag(tag)
        templates = [
            {
                "template_id": t.template_id,
                "name": t.name,
                "content": t.content,
                "category": t.category.value,
                "tags": t.tags,
                "variables": t.variables,
                "priority": t.priority,
                "is_active": t.is_active
            } for t in found_templates
        ]
    elif category:
        # Get templates by category
        from app.ai_assistant.template_manager import TemplateCategory
        try:
            cat_enum = TemplateCategory(category)
            found_templates = template_manager.get_templates_by_category(cat_enum)
            templates = [
                {
                    "template_id": t.template_id,
                    "name": t.name,
                    "content": t.content,
                    "category": t.category.value,
                    "tags": t.tags,
                    "variables": t.variables,
                    "priority": t.priority,
                    "is_active": t.is_active
                } for t in found_templates
            ]
        except ValueError:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invalid category: {category}"
            )
    else:
        # Get all templates
        all_templates = template_manager._templates.values()
        templates = [
            {
                "template_id": t.template_id,
                "name": t.name,
                "content": t.content,
                "category": t.category.value,
                "tags": t.tags,
                "variables": t.variables,
                "priority": t.priority,
                "is_active": t.is_active
            } for t in all_templates
        ]
    
    return {"templates": templates}


@router.get("/memory/stats")
async def get_memory_stats():
    """Get conversation memory statistics."""
    return {
        "conversation_stats": conversation_memory.get_session_summary("global") if "global" in conversation_memory._memory else {},
        "template_stats": template_manager.get_statistics(),
        "active_sessions": len(conversation_memory._memory),
        "total_users_with_sessions": len(conversation_memory._user_sessions)
    }

