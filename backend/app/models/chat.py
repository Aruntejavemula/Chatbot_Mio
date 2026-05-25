"""Chat models - Pydantic schemas for chat and message data."""

from pydantic import BaseModel
from typing import Optional


class ChatCreate(BaseModel):
    """Schema for creating a new chat session."""

    title: Optional[str] = None
    model: str = "gpt-4"


class ChatResponse(BaseModel):
    """Schema for chat session response data."""

    id: str
    title: str
    model: str
    created_at: str
    updated_at: str


class MessageCreate(BaseModel):
    """Schema for creating a new message."""

    content: str
    role: str = "user"
    model: str = "gpt-4"


class MessageResponse(BaseModel):
    """Schema for message response data."""

    id: str
    chat_id: str
    content: str
    role: str
    tokens: int = 0
    created_at: str
