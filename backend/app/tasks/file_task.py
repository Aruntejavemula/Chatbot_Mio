"""Async task for file processing."""

import base64
import logging
from typing import Any

from app.worker import celery_app
from app.services.file_service import FileService

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=2)
def process_file(
    self,
    user_id: str,
    file_bytes_b64: str,
    filename: str,
    content_type: str,
) -> dict[str, Any]:
    """Process a file as a background task.

    Args:
        user_id: The user who uploaded the file.
        file_bytes_b64: Base64-encoded file content.
        filename: Original filename.
        content_type: MIME type of the file.

    Returns:
        Dictionary with status and extracted text result.
    """
    try:
        logger.info("Processing file for user=%s, filename=%s", user_id, filename)
        file_service = FileService()
        raw = base64.b64decode(file_bytes_b64)
        result = file_service.extract_text(raw, filename, content_type)
        logger.info("File processing completed for user=%s, filename=%s", user_id, filename)
        return {"status": "done", "result": result}
    except Exception as exc:
        logger.error("File processing failed for user=%s: %s", user_id, str(exc))
        raise self.retry(exc=exc, countdown=5)
