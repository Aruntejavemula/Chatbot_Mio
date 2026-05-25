"""User models for request/response validation."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class UserCreate(BaseModel):
    """Model for creating a new user."""

    email: str = Field(..., description="User email address")
    name: str = Field(..., description="User display name")
    avatar_url: Optional[str] = Field(None, description="URL to user avatar image")


class UserResponse(BaseModel):
    """Model for user API responses."""

    id: str = Field(..., description="Unique user ID")
    email: str = Field(..., description="User email address")
    name: str = Field(..., description="User display name")
    avatar_url: Optional[str] = Field(None, description="URL to user avatar image")
    created_at: datetime = Field(..., description="Account creation timestamp")

    class Config:
        from_attributes = True


class UserUpdate(BaseModel):
    """Model for updating user profile."""

    name: Optional[str] = Field(None, description="Updated display name")
    avatar_url: Optional[str] = Field(None, description="Updated avatar URL")
