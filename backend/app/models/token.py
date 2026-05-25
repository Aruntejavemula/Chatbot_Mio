"""Token usage models for request/response validation."""

from datetime import datetime

from pydantic import BaseModel, Field


class TokenUsageResponse(BaseModel):
    """Model for token usage API responses."""

    daily_used: int = Field(default=0, description="Tokens used today")
    daily_limit: int = Field(default=0, description="Daily token limit")
    monthly_used: int = Field(default=0, description="Tokens used this month")
    monthly_limit: int = Field(default=0, description="Monthly token limit")
    current_model: str = Field(default="", description="Current default model")
    reset_time: datetime = Field(..., description="Next reset timestamp")
    can_use_our_tokens: bool = Field(default=False, description="Whether user can use platform tokens")

    class Config:
        from_attributes = True


class TokenUsageUpdate(BaseModel):
    """Model for recording token usage."""

    tokens_input: int = Field(..., description="Input tokens consumed")
    tokens_output: int = Field(..., description="Output tokens consumed")
    model_used: str = Field(..., description="Model that consumed tokens")
