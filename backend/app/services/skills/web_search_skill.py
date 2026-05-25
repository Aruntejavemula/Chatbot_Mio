"""Web search skill using Brave Search API."""

import logging
from typing import Any

from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)


class WebSearchSkill(BaseSkill):
    """Search the web for current information."""

    name = "web_search"
    description = "Search the web for current information on any topic"
    parameters = {
        "type": "object",
        "properties": {
            "query": {
                "type": "string",
                "description": "The search query",
            },
        },
        "required": ["query"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Execute web search."""
        try:
            query = params.get("query", "")
            if not query:
                return {"error": "Query is required"}
            # Placeholder: integrate with search_service
            return {"results": [], "query": query}
        except Exception as e:
            logger.error("Web search skill error: %s", str(e))
            return {"error": str(e)}
