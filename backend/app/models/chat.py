"""Chat and message models for request/response validation."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class ChatCreate(BaseModel):
    """Model for creating a new chat."""

    model: str = Field(..., description="AI model name")
    provider: str = Field(..., description="AI provider name")


class ChatResponse(BaseModel):
    """Model for chat API responses."""

    id: str = Field(..., description="Unique chat ID")
    user_id: str = Field(..., description="Owner user ID")
    title: str = Field(default="New Chat", description="Chat title")
    model: str = Field(..., description="AI model used")
    provider: str = Field(..., description="AI provider used")
    message_count: int = Field(default=0, description="Number of messages")
    last_preview: str = Field(default="", description="Preview of last message")
    storage_type: str = Field(default="local", description="Storage tier: local/drive/cloud")
    created_at: datetime = Field(..., description="Chat creation timestamp")
    updated_at: datetime = Field(..., description="Last update timestamp")

    class Config:
        from_attributes = True


class ChatUpdate(BaseModel):
    """Model for updating a chat."""

    title: Optional[str] = Field(None, description="Updated chat title")


class MessageCreate(BaseModel):
    """Model for creating a new message."""

    chat_id: str = Field(..., description="Parent chat ID")
    content: str = Field(..., description="Message content")
    model: str = Field(..., description="AI model to use")
    provider: str = Field(..., description="AI provider to use")
    use_our_tokens: bool = Field(default=False, description="Use platform tokens")
    project_id: Optional[str] = Field(None, description="Optional project ID for scoped context")


class MessageResponse(BaseModel):
    """Model for message API responses."""

    id: str = Field(..., description="Unique message ID")
    chat_id: str = Field(..., description="Parent chat ID")
    role: str = Field(..., description="Message role: user/assistant/system")
    content: str = Field(..., description="Message content")
    tokens_input: Optional[int] = Field(None, description="Input tokens used")
    tokens_output: Optional[int] = Field(None, description="Output tokens used")
    model: Optional[str] = Field(None, description="Model that generated response")
    created_at: datetime = Field(..., description="Message creation timestamp")

    class Config:
        from_attributes = True
