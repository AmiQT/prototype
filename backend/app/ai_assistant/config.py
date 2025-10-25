"""Configuration helpers for AI assistant module."""

from functools import lru_cache
from pydantic_settings import BaseSettings, SettingsConfigDict
from pydantic import Field


class AISettings(BaseSettings):
    """Application settings for AI assistant behaviour."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        extra="ignore",
    )

    ai_enabled: bool = Field(default=True, env="AI_ASSISTANT_ENABLED")
    
    # Google Gemini API (FREE tier with tool calling!)
    enable_gemini: bool = Field(default=True, env="AI_GEMINI_ENABLED")
    gemini_api_key: str | None = Field(default=None, env="GEMINI_API_KEY")


@lru_cache()
def get_ai_settings() -> AISettings:
    """Return cached application settings for AI assistant."""

    return AISettings()

