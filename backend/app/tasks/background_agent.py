"""Async task for background agent execution."""

import logging
from typing import Any, Optional

from app.worker import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=1, time_limit=300)
def run_background_agent(
    self,
    user_id: str,
    prompt: str,
    skills: list[str],
    connectors: list[str],
    api_key: str,
    model: str,
    byok: bool,
    task_id: Optional[str] = None,
) -> dict[str, Any]:
    """Run a background agent as an async task.

    Args:
        user_id: The user who initiated the agent.
        prompt: The prompt/instruction for the agent.
        skills: List of skill identifiers to use.
        connectors: List of connector identifiers to use.
        api_key: The API key for the AI provider.
        model: The model to use.
        byok: Whether the user is using their own key.
        task_id: Optional task ID for tracking.

    Returns:
        Dictionary with status and agent result.
    """
    try:
        logger.info(
            "Starting background agent for user=%s, model=%s, skills=%s",
            user_id,
            model,
            skills,
        )

        # Placeholder: actual agent execution logic will be added later
        result = {
            "status": "done",
            "user_id": user_id,
            "prompt": prompt[:100],
            "model": model,
            "skills_used": skills,
            "connectors_used": connectors,
            "output": f"Background agent completed: {prompt[:100]}",
        }

        logger.info("Background agent completed for user=%s", user_id)
        return result
    except Exception as exc:
        logger.error("Background agent failed for user=%s: %s", user_id, str(exc))
        raise self.retry(exc=exc, countdown=10)
