"""Application configuration using Pydantic BaseSettings."""

from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    OPENAI_WHISPER_KEY: str = ""
    APP_NAME: str = "Mio"
    DEBUG: bool = False

    model_config = {
        "env_file": ".env",
    }


settings = Settings()
