"""Token models - Pydantic schemas for token usage and limits."""

from pydantic import BaseModel


class TokenUsage(BaseModel):
    """Schema for token usage data."""

    tokens_used: int
    tokens_limit: int
    reset_date: str
    percentage_used: float


class TokenLimits(BaseModel):
    """Schema for token limits by plan."""

    plan: str
    daily_limit: int
    monthly_limit: int
    models_available: list[str]
