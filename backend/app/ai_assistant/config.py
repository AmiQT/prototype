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
    enable_openrouter: bool = Field(default=True, env="AI_OPENROUTER_ENABLED")
    openrouter_api_key: str | None = Field(default=None, env="OPENROUTER_API_KEY")
    openrouter_default_model: str = Field(
        default="qwen/qwen3-30b-a3b:free",
        env="OPENROUTER_DEFAULT_MODEL",
    )
    openrouter_daily_limit: int = Field(default=50, env="OPENROUTER_DAILY_LIMIT")
    openrouter_timeout_seconds: int = Field(default=25, env="OPENROUTER_TIMEOUT")
    openrouter_quota_reset_hour: int = Field(default=0, env="OPENROUTER_RESET_HOUR")


@lru_cache()
def get_ai_settings() -> AISettings:
    """Return cached application settings for AI assistant."""

    return AISettings()

