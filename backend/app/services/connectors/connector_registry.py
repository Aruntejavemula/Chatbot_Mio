"""Connector registry for managing MCP connectors."""

import logging
from typing import Any

from app.services.connectors.base_connector import BaseConnector
from app.services.connectors.google_drive_connector import GoogleDriveConnector

logger = logging.getLogger(__name__)


class ConnectorRegistry:
    """Registry for managing MCP connectors."""

    def __init__(self) -> None:
        """Initialize the connector registry."""
        self._connectors: dict[str, BaseConnector] = {}

    def register(self, connector: BaseConnector) -> None:
        """Register a connector."""
        self._connectors[connector.name] = connector
        logger.info("Registered connector: %s", connector.name)

    def get(self, name: str) -> BaseConnector | None:
        """Get a connector by name."""
        return self._connectors.get(name)

    def list_all(self, connected_names: list[str] | None = None) -> list[dict[str, Any]]:
        """List all connectors with connection status."""
        connected = connected_names or []
        return [
            c.to_metadata(is_connected=c.name in connected)
            for c in self._connectors.values()
        ]


# Global registry instance
connector_registry = ConnectorRegistry()
connector_registry.register(GoogleDriveConnector())
