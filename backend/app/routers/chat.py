"""Chat router for streaming chat and message count tracking."""
from __future__ import annotations

import logging
from datetime import datetime, timezone, timedelta
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth import get_current_user
from app.middleware.rate_limit import rate_limit
from app.services.message_guard import (
    FREE_DAILY_MESSAGE_LIMIT,
    FREE_MESSAGE_WARNING,
    message_guard,
)

logger = logging.getLogger(__name__)

router = APIRouter()

# Rate limit constants
CHAT_RATE_LIMIT_MAX: int = 10
CHAT_RATE_LIMIT_WINDOW: int = 60


# --- Request/Response Models ---


class ChatStreamRequest(BaseModel):
    """Request model for chat streaming."""

    chat_id: str = Field(..., min_length=1)
    content: str = Field(..., min_length=1)
    model: str = Field(..., min_length=1)
    provider: str = Field(..., min_length=1)
    use_our_tokens: bool = Field(default=False)
    project_id: Optional[str] = None


class ChatStreamResponse(BaseModel):
    """Response model for chat stream (placeholder)."""

    message: str
    chat_id: str


class MessageCountResponse(BaseModel):
    """Response model for message count status."""

    count: int
    limit: int
    remaining: int
    warning: bool
    resets_at: str


# --- Endpoints ---


@router.post(
    "/stream",
    response_model=ChatStreamResponse,
    summary="Stream a chat message",
)
async def chat_stream(
    body: ChatStreamRequest,
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=CHAT_RATE_LIMIT_MAX,
            window_seconds=CHAT_RATE_LIMIT_WINDOW,
        )
    ),
) -> ChatStreamResponse:
    """Process a chat message with streaming response.

    Enforces the daily message limit for free-plan users via
    the message guard service before processing.
    """
    user_id = current_user.get("user_id", "unknown")
    plan = current_user.get("plan", "free")

    # Check message limit before processing
    limit_status = message_guard.check_message_limit(user_id, plan)

    if not limit_status["allowed"]:
        logger.warning(
            "Message limit reached: user=%s, count=%d",
            user_id,
            limit_status["current_count"],
        )
        raise HTTPException(
            status_code=429,
            detail={
                "detail": "Daily message limit reached",
                "type": "message_limit",
                "limit": FREE_DAILY_MESSAGE_LIMIT,
                "current_count": limit_status["current_count"],
            },
        )

    logger.info(
        "Processing chat stream: user=%s, chat_id=%s, model=%s",
        user_id,
        body.chat_id,
        body.model,
    )

    # Placeholder: In production, stream response from AI provider
    # After successful processing, increment the message count
    message_guard.increment_message_count(user_id)

    return ChatStreamResponse(
        message="Placeholder streaming response",
        chat_id=body.chat_id,
    )


@router.get(
    "/tokens/message-count",
    response_model=MessageCountResponse,
    summary="Get current message count and limits",
)
async def get_message_count(
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(
        rate_limit(
            max_requests=CHAT_RATE_LIMIT_MAX,
            window_seconds=CHAT_RATE_LIMIT_WINDOW,
        )
    ),
) -> MessageCountResponse:
    """Get the current message count, limit, and reset time for the user."""
    user_id = current_user.get("user_id", "unknown")
    plan = current_user.get("plan", "free")

    count = message_guard.get_message_count(user_id)
    remaining = max(0, FREE_DAILY_MESSAGE_LIMIT - count)
    warning = count >= FREE_MESSAGE_WARNING

    # Calculate next midnight UTC
    now = datetime.now(timezone.utc)
    tomorrow = now.date() + timedelta(days=1)
    resets_at = datetime(
        tomorrow.year, tomorrow.month, tomorrow.day, tzinfo=timezone.utc
    ).isoformat()

    logger.debug(
        "Message count request: user=%s, count=%d, remaining=%d",
        user_id,
        count,
        remaining,
    )

    return MessageCountResponse(
        count=count,
        limit=FREE_DAILY_MESSAGE_LIMIT,
        remaining=remaining,
        warning=warning,
        resets_at=resets_at,
    )
