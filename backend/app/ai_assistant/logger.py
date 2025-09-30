"""Logging helper for AI assistant actions."""

from __future__ import annotations

import logging
from typing import Any

from . import history


logger = logging.getLogger("app.ai_assistant")


def log_ai_action(user_id: str, command: str, response: dict[str, Any]) -> None:
    """Structured log + in-memory history (future: persist to DB)."""

    payload = {
        "user_id": user_id,
        "command": command,
        "response": response,
    }

    history.add_history_entry(payload)

    logger.info(
        "AI Action | user=%s | success=%s | source=%s | message=%s",
        user_id,
        response.get("success"),
        response.get("source"),
        response.get("message"),
    )

