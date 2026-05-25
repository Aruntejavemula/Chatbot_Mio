"""Voice router - text-to-speech endpoint."""

import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


class TTSRequest(BaseModel):
    """Request model for text-to-speech."""

    text: str = Field(..., description="Text to synthesize", min_length=1, max_length=4096)
    voice: str = Field(default="alloy", description="Voice to use for synthesis")


@router.post("/tts")
async def text_to_speech(
    body: TTSRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Convert text to speech using OpenAI TTS API.

    Currently returns 501 as OpenAI API key is not configured.

    Args:
        body: TTS request with text and voice selection.
        current_user: Authenticated user.

    Returns:
        Audio data (when implemented).

    Raises:
        HTTPException: 501 if TTS service is not configured.
    """
    if len(body.text) > 4096:
        raise HTTPException(status_code=400, detail="Text must be 4096 characters or less")

    # Placeholder: TTS not yet configured
    raise HTTPException(
        status_code=501,
        detail="TTS service not configured. OpenAI API key required.",
    )
