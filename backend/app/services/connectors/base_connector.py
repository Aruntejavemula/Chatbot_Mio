"""Base class for MCP connectors."""

import logging
from abc import ABC, abstractmethod
from typing import Any

logger = logging.getLogger(__name__)


class BaseConnector(ABC):
    """Abstract base class for all MCP connectors."""

    name: str = ""
    label: str = ""
    description: str = ""
    auth_type: str = "oauth2"
    scopes: list[str] = []

    @abstractmethod
    async def get_tools(self, access_token: str) -> list[dict[str, Any]]:
        """Return tool definitions this connector provides."""
        pass

    @abstractmethod
    async def execute_tool(
        self, tool_name: str, params: dict[str, Any], access_token: str
    ) -> dict[str, Any]:
        """Execute a specific tool."""
        pass

    def to_metadata(self, is_connected: bool = False) -> dict[str, Any]:
        """Return connector metadata."""
        return {
            "name": self.name,
            "label": self.label,
            "description": self.description,
            "auth_type": self.auth_type,
            "connected": is_connected,
        }
