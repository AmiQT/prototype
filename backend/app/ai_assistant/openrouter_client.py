"""Lightweight OpenRouter client wrapper."""

from __future__ import annotations

import logging
from typing import Any, Dict

import httpx

from .config import AISettings

logger = logging.getLogger(__name__)


class OpenRouterClient:
    """Simple async client for OpenRouter free tier usage."""

    BASE_URL = "https://openrouter.ai/api/v1/chat/completions"

    def __init__(self, settings: AISettings) -> None:
        self.settings = settings
        self._client = httpx.AsyncClient(timeout=settings.openrouter_timeout_seconds)

    async def close(self) -> None:
        await self._client.aclose()

    async def generate(self, model: str, messages: list[dict[str, str]], max_tokens: int = 512,
                       temperature: float = 0.7) -> Dict[str, Any]:
        if not self.settings.openrouter_api_key:
            raise ValueError("OpenRouter API key is not configured")

        headers = {
            "Authorization": f"Bearer {self.settings.openrouter_api_key}",
            "HTTP-Referer": "https://uthm-dashboard",
            "X-Title": "UTHM Talent Dashboard",
        }

        payload = {
            "model": model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        logger.info("Calling OpenRouter model=%s", model)
        logger.debug("OpenRouter payload: %s", payload)
        logger.debug("OpenRouter headers: %s", {k: v[:20] + "..." if k == "Authorization" else v for k, v in headers.items()})
        
        response = await self._client.post(self.BASE_URL, headers=headers, json=payload)

        # Handle rate limit / 429 gracefully untuk fallback pseudo AI
        if response.status_code == 429:
            raise RuntimeError("OpenRouter rate limit reached (429)")

        response.raise_for_status()
        data = response.json()
        logger.debug("OpenRouter response: %s", data)
        return data

    async def chat_completion(self, model: str, messages: list[dict[str, str]], max_tokens: int = 800,
                              temperature: float = 0.7) -> str:
        """Wrapper untuk chat completion dengan handling response."""
        if not self.settings.openrouter_api_key:
            raise ValueError("OpenRouter API key is not configured")

        headers = {
            "Authorization": f"Bearer {self.settings.openrouter_api_key}",
            "HTTP-Referer": "https://uthm-dashboard",
            "X-Title": "UTHM Talent Dashboard",
        }

        payload = {
            "model": model,
            "messages": messages,
            "max_tokens": max_tokens,
            "temperature": temperature,
        }

        logger.info("Calling OpenRouter chat completion model=%s", model)
        logger.debug("OpenRouter payload: %s", payload)
        
        response = await self._client.post(self.BASE_URL, headers=headers, json=payload)

        # Handle rate limit / 429 gracefully untuk fallback pseudo AI
        if response.status_code == 429:
            raise RuntimeError("OpenRouter rate limit reached (429)")

        response.raise_for_status()
        data = response.json()
        
        # Extract the content from the response
        if "choices" in data and len(data["choices"]) > 0:
            content = data["choices"][0]["message"]["content"]
            logger.debug("OpenRouter response content: %s", content[:200] + "..." if len(content) > 200 else content)
            return content
        else:
            logger.error("Unexpected response format: %s", data)
            raise RuntimeError(f"Unexpected response format from OpenRouter: {data}")

