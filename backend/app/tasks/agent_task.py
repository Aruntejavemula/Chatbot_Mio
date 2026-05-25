"""Async task for AI agent execution."""

import logging
from typing import Any

from app.worker import celery_app
from app.services.ai_service import AIService

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=1)
def run_agent_task(
    self,
    user_id: str,
    messages: list[dict[str, str]],
    tools: list[dict[str, Any]],
    api_key: str,
    model: str,
    byok: bool,
) -> dict[str, Any]:
    """Run an AI agent task as a background job.

    Args:
        user_id: The user who initiated the agent task.
        messages: Conversation messages for the agent.
        tools: Available tools for the agent.
        api_key: The API key for the AI provider.
        model: The model to use.
        byok: Whether the user is using their own key.

    Returns:
        Dictionary with status and agent result.
    """
    try:
        logger.info("Starting agent task for user=%s, model=%s", user_id, model)
        ai = AIService()
        result = ai.run_agent(messages, tools, api_key, model, byok)
        logger.info("Agent task completed for user=%s", user_id)
        return {"status": "done", "result": result}
    except Exception as exc:
        logger.error("Agent task failed for user=%s: %s", user_id, str(exc))
        raise self.retry(exc=exc, countdown=10)
