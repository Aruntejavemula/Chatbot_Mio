"""Application configuration using pydantic-settings."""

from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    """Application settings loaded from environment variables."""

    # Supabase
    SUPABASE_URL: str = ""
    SUPABASE_SERVICE_KEY: str = ""

    # Stripe
    STRIPE_SECRET_KEY: str = ""
    STRIPE_WEBHOOK_SECRET: str = ""
    STRIPE_BASIC_PRICE_ID_MONTHLY: str = ""
    STRIPE_BASIC_PRICE_ID_ANNUAL: str = ""
    STRIPE_PRO_PRICE_ID_MONTHLY: str = ""
    STRIPE_PRO_PRICE_ID_ANNUAL: str = ""

    # Razorpay
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""

    # Redis
    UPSTASH_REDIS_URL: str = ""
    UPSTASH_REDIS_TOKEN: str = ""

    # Security
    ENCRYPTION_SECRET: str = ""

    # Email
    RESEND_API_KEY: str = ""

    # App
    ALLOWED_ORIGINS: str = "http://localhost:8080"
    ENVIRONMENT: str = "development"

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
