"""Voice transcription router for audio-to-text conversion."""

import logging
import time
from typing import Any

import httpx
from fastapi import APIRouter, Depends, HTTPException, UploadFile
from pydantic import BaseModel

from app.config import settings
from app.middleware.auth import get_current_user
from app.middleware.rate_limit import rate_limit

logger = logging.getLogger(__name__)

router = APIRouter()

MAX_FILE_SIZE: int = 25 * 1024 * 1024
ACCEPTED_FORMATS: set[str] = {"m4a", "mp3", "wav", "webm", "ogg"}

OPENAI_WHISPER_URL: str = "https://api.openai.com/v1/audio/transcriptions"


class TranscriptionResponse(BaseModel):
    """Response model for audio transcription."""

    transcript: str
    duration: float
    language: str


def _get_file_extension(filename: str | None) -> str:
    """Extract file extension from a filename.

    Args:
        filename: The name of the uploaded file.

    Returns:
        The lowercase file extension without the dot.

    Raises:
        HTTPException: If the filename is missing or has no extension.
    """
    if not filename:
        raise HTTPException(
            status_code=400,
            detail="Filename is required.",
        )

    parts = filename.rsplit(".", 1)
    if len(parts) < 2:
        raise HTTPException(
            status_code=400,
            detail="File must have an extension.",
        )

    return parts[1].lower()


def _validate_format(extension: str) -> None:
    """Validate that the file format is accepted.

    Args:
        extension: The file extension to validate.

    Raises:
        HTTPException: If the format is not in ACCEPTED_FORMATS.
    """
    if extension not in ACCEPTED_FORMATS:
        logger.warning("Rejected file with unsupported format: %s", extension)
        raise HTTPException(
            status_code=400,
            detail=(
                f"Unsupported audio format: .{extension}. "
                f"Accepted formats: {', '.join(sorted(ACCEPTED_FORMATS))}."
            ),
        )


def _validate_file_size(content: bytes) -> None:
    """Validate that the file size is within limits.

    Args:
        content: The file content as bytes.

    Raises:
        HTTPException: If the file exceeds MAX_FILE_SIZE.
    """
    if len(content) > MAX_FILE_SIZE:
        logger.warning(
            "Rejected file exceeding size limit: %d bytes", len(content)
        )
        raise HTTPException(
            status_code=400,
            detail=f"File size exceeds maximum of {MAX_FILE_SIZE // (1024 * 1024)}MB.",
        )


def _get_api_key() -> str:
    """Get the OpenAI API key for Whisper transcription.

    Returns:
        The API key string.

    Raises:
        HTTPException: If no API key is available.
    """
    if settings.OPENAI_WHISPER_KEY:
        return settings.OPENAI_WHISPER_KEY

    # Placeholder: In production, check user's BYOK key from api_keys table
    logger.warning("No OpenAI API key configured for voice transcription")
    raise HTTPException(
        status_code=400,
        detail="Add OpenAI API key for voice transcription",
    )


@router.post(
    "/transcribe",
    response_model=TranscriptionResponse,
    summary="Transcribe audio file to text",
)
async def transcribe_audio(
    file: UploadFile,
    current_user: dict[str, Any] = Depends(get_current_user),
    _rate_limit: None = Depends(rate_limit(max_requests=30, window_seconds=60)),
) -> TranscriptionResponse:
    """Transcribe an uploaded audio file using OpenAI Whisper API.

    Accepts audio files in m4a, mp3, wav, webm, or ogg format.
    Maximum file size is 25MB. Requires a valid OpenAI API key
    either configured at the system level or provided by the user.

    Args:
        file: The uploaded audio file.
        current_user: The authenticated user (injected via dependency).
        _rate_limit: Rate limit enforcement (injected via dependency).

    Returns:
        TranscriptionResponse containing the transcript, duration, and language.

    Raises:
        HTTPException: On validation errors (400), auth errors (401),
            rate limit errors (429), or upstream API errors (502).
    """
    logger.info(
        "Transcription request from user=%s, file=%s",
        current_user.get("user_id"),
        file.filename,
    )

    # Validate file format
    extension = _get_file_extension(file.filename)
    _validate_format(extension)

    # Read and validate file size
    try:
        content = await file.read()
    except Exception as exc:
        logger.error("Failed to read uploaded file: %s", exc)
        raise HTTPException(
            status_code=400,
            detail="Failed to read uploaded file.",
        ) from exc

    _validate_file_size(content)

    # Get API key
    api_key = _get_api_key()

    # Send to OpenAI Whisper API
    start_time = time.time()
    try:
        async with httpx.AsyncClient(timeout=60.0) as client:
            response = await client.post(
                OPENAI_WHISPER_URL,
                headers={"Authorization": f"Bearer {api_key}"},
                files={
                    "file": (
                        file.filename,
                        content,
                        file.content_type or "audio/mpeg",
                    ),
                },
                data={
                    "model": "whisper-1",
                    "response_format": "json",
                    "language": "en",
                },
            )
    except httpx.TimeoutException as exc:
        logger.error("OpenAI Whisper API request timed out: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Transcription service timed out. Please try again.",
        ) from exc
    except httpx.RequestError as exc:
        logger.error("OpenAI Whisper API request failed: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Failed to connect to transcription service.",
        ) from exc

    duration = time.time() - start_time

    if response.status_code != 200:
        logger.error(
            "OpenAI Whisper API returned status=%d, body=%s",
            response.status_code,
            response.text[:200],
        )
        raise HTTPException(
            status_code=502,
            detail="Transcription service returned an error.",
        )

    try:
        result = response.json()
    except Exception as exc:
        logger.error("Failed to parse OpenAI Whisper API response: %s", exc)
        raise HTTPException(
            status_code=502,
            detail="Invalid response from transcription service.",
        ) from exc

    transcript = result.get("text", "")
    logger.info(
        "Transcription completed for user=%s, duration=%.2fs, length=%d",
        current_user.get("user_id"),
        duration,
        len(transcript),
    )

    return TranscriptionResponse(
        transcript=transcript,
        duration=round(duration, 2),
        language="en",
    )
