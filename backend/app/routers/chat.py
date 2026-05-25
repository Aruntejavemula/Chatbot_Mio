"""Chat router - handles chat sessions, messages, and AI streaming."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.get("/chats")
async def get_chats() -> dict:
    """Get all chat sessions for the current user."""
    pass


@router.post("/chats")
async def create_chat() -> dict:
    """Create a new chat session."""
    pass


@router.delete("/chats/{chat_id}")
async def delete_chat(chat_id: str) -> dict:
    """Delete a chat session by ID."""
    pass


@router.patch("/chats/{chat_id}")
async def update_chat(chat_id: str) -> dict:
    """Update a chat session (e.g., rename)."""
    pass


@router.post("/stream")
async def stream_response() -> dict:
    """Stream an AI response for a given message."""
    pass


@router.get("/chats/{chat_id}/messages")
async def get_messages(chat_id: str) -> dict:
    """Get all messages for a specific chat session."""
    pass
