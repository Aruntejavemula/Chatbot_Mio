"""User models - Pydantic schemas for user-related data."""

from pydantic import BaseModel
from typing import Optional


class UserCreate(BaseModel):
    """Schema for creating a new user."""

    email: str
    name: str
    avatar_url: Optional[str] = None
    provider: str


class UserResponse(BaseModel):
    """Schema for user response data."""

    id: str
    email: str
    name: str
    avatar_url: Optional[str] = None
    plan: str = "free"
    created_at: str


class UserProfile(BaseModel):
    """Schema for user profile data."""

    id: str
    email: str
    name: str
    avatar_url: Optional[str] = None
    plan: str = "free"
    tokens_used: int = 0
    tokens_limit: int = 0
    device_count: int = 0
