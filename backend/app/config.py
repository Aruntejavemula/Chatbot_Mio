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

    STRIPE_MIDDLE_BASIC_PRICE_ID: str = ""
    STRIPE_MIDDLE_PRO_PRICE_ID: str = ""

    # Razorpay
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""
    RAZORPAY_BASIC_PLAN_ID: str = ""
    RAZORPAY_PRO_PLAN_ID: str = ""
    RAZORPAY_BASIC_ANNUAL_PLAN_ID: str = ""
    RAZORPAY_PRO_ANNUAL_PLAN_ID: str = ""

    # Redis
    UPSTASH_REDIS_URL: str = ""
    UPSTASH_REDIS_TOKEN: str = ""

    # Security
    ENCRYPTION_SECRET: str = ""

    # Email
    RESEND_API_KEY: str = ""

    # Search
    BRAVE_SEARCH_API_KEY: str = ""

    # OpenAI
    OPENAI_API_KEY: str = ""

    # DeepSeek
    DEEPSEEK_API_KEY: str = ""

    # App
    ALLOWED_ORIGINS: str = "http://localhost:8080"
    ENVIRONMENT: str = "development"

    # Admin
    ADMIN_EMAIL: str = ""
    FRONTEND_URL: str = "https://mio.app"

    class Config:
        env_file = ".env"
        case_sensitive = True


@lru_cache()
def get_settings() -> Settings:
    """Get cached settings instance."""
    return Settings()
