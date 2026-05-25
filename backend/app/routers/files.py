"""Files router - handles file upload and processing for AI context."""

import logging
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, HTTPException, UploadFile

from app.services.file_service import (
    MAX_FILE_SIZE,
    SUPPORTED_TYPES,
    file_service,
)

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/upload")
async def upload_file(file: UploadFile):
    """Upload and process a file for AI consumption."""
    if not file.filename:
        raise HTTPException(status_code=400, detail="No filename provided")

    ext = Path(file.filename).suffix.lower()
    if ext not in SUPPORTED_TYPES:
        supported = ", ".join(sorted(SUPPORTED_TYPES.keys()))
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported file type '{ext}'. Supported: {supported}",
        )

    content = await file.read()

    if len(content) > MAX_FILE_SIZE:
        raise HTTPException(
            status_code=400,
            detail=f"File too large. Maximum size is {MAX_FILE_SIZE // (1024 * 1024)}MB",
        )

    try:
        ai_content = file_service.process_file(file.filename, content)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error processing file {file.filename}: {e}")
        raise HTTPException(status_code=500, detail="Error processing file")

    # Build preview from content
    preview_text = ai_content.get("content", "")
    preview = preview_text[:200] if preview_text else ""

    return {
        "file_id": str(uuid4()),
        "filename": file.filename,
        "type": ai_content["type"],
        "size_kb": round(len(content) / 1024, 2),
        "preview": preview,
        "ai_ready": True,
        "ai_content": ai_content,
    }
