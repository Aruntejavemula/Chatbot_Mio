"""Files router - handles file upload and processing for AI context."""

import base64
import logging
from pathlib import Path
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, UploadFile

from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.services.file_service import (
    MAX_FILE_SIZE,
    SUPPORTED_TYPES,
    file_service,
)
from app.tasks.file_task import process_file

logger = logging.getLogger(__name__)

router = APIRouter()


@router.post("/upload")
async def upload_file(
    file: UploadFile,
    current_user: dict = Depends(get_current_user),
):
    """Upload and process a file asynchronously for AI consumption."""
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

    user_id = current_user["id"]
    file_bytes_b64 = base64.b64encode(content).decode()

    task = process_file.delay(
        user_id=user_id,
        file_bytes_b64=file_bytes_b64,
        filename=file.filename,
        content_type=file.content_type or "application/octet-stream",
    )
    logger.info("File processing task dispatched for user=%s, task_id=%s", user_id, task.id)
    return {"task_id": task.id, "status": "processing", "filename": file.filename}
