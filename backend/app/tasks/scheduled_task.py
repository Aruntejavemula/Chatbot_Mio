"""Async task for scheduled task execution."""

import logging
from typing import Any

from app.worker import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(bind=True)
def run_scheduled_task(
    self,
    task_id: str,
    user_id: str,
    prompt: str,
) -> dict[str, Any]:
    """Run a scheduled task as a background job.

    Args:
        task_id: The scheduled task ID.
        user_id: The user who owns the scheduled task.
        prompt: The prompt to execute.

    Returns:
        Dictionary with status and result.
    """
    try:
        logger.info(
            "Executing scheduled task=%s for user=%s, prompt=%s",
            task_id,
            user_id,
            prompt[:50],
        )

        # Placeholder: actual execution logic will be added later
        result = {
            "status": "done",
            "task_id": task_id,
            "user_id": user_id,
            "output": f"Scheduled task executed: {prompt[:100]}",
        }

        logger.info("Scheduled task=%s completed for user=%s", task_id, user_id)
        return result
    except Exception as exc:
        logger.error(
            "Scheduled task=%s failed for user=%s: %s", task_id, user_id, str(exc)
        )
        raise
