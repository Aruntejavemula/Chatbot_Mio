"""Async task for deep research processing."""

import logging
from typing import Any

from app.worker import celery_app
from app.services.search_service import SearchService
from app.services.ai_service import AIService

logger = logging.getLogger(__name__)


@celery_app.task(bind=True, max_retries=2)
def run_deep_research(
    self,
    user_id: str,
    query: str,
    api_key: str,
    model: str,
    byok: bool,
) -> dict[str, Any]:
    """Run deep research as a background task.

    Args:
        user_id: The user who initiated the research.
        query: The research query.
        api_key: The API key for the AI provider.
        model: The model to use.
        byok: Whether the user is using their own key.

    Returns:
        Dictionary with status and result.
    """
    try:
        logger.info("Starting deep research for user=%s, query=%s", user_id, query[:50])
        search = SearchService()
        ai = AIService()
        results = search.deep_search(query)
        summary = ai.summarize_research(results, query, api_key, model, byok)
        logger.info("Deep research completed for user=%s", user_id)
        return {"status": "done", "result": summary}
    except Exception as exc:
        logger.error("Deep research failed for user=%s: %s", user_id, str(exc))
        raise self.retry(exc=exc, countdown=5)
