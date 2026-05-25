"""Connectors router for MCP connector management."""

import logging
from typing import Any

from fastapi import APIRouter, Depends, HTTPException

from app.middleware.auth_middleware import get_current_user
from app.services.connectors.connector_registry import connector_registry

logger = logging.getLogger(__name__)

router = APIRouter()


@router.get("")
async def list_connectors(
    current_user: dict = Depends(get_current_user),
) -> dict[str, Any]:
    """List all available connectors with connection status.

    Args:
        current_user: Authenticated user.

    Returns:
        Dictionary with list of connector metadata.
    """
    logger.info("Listing connectors for user=%s", current_user.get("id"))
    # Placeholder: in production, check connector_tokens table
    connected_names: list[str] = []
    connectors = connector_registry.list_all(connected_names=connected_names)
    return {"connectors": connectors}


@router.get("/{name}/auth-url")
async def get_auth_url(
    name: str,
    current_user: dict = Depends(get_current_user),
) -> dict[str, str]:
    """Get OAuth URL for a connector.

    Args:
        name: Connector name.
        current_user: Authenticated user.

    Returns:
        Dictionary with OAuth authorization URL.
    """
    connector = connector_registry.get(name)
    if not connector:
        raise HTTPException(status_code=404, detail=f"Connector '{name}' not found")
    # Placeholder: generate real OAuth URL with state param
    return {"auth_url": f"https://accounts.google.com/o/oauth2/auth?scope={'+'.join(connector.scopes)}"}


@router.delete("/{name}")
async def disconnect_connector(
    name: str,
    current_user: dict = Depends(get_current_user),
) -> dict[str, str]:
    """Disconnect a connector by removing stored tokens.

    Args:
        name: Connector name.
        current_user: Authenticated user.

    Returns:
        Success message.
    """
    connector = connector_registry.get(name)
    if not connector:
        raise HTTPException(status_code=404, detail=f"Connector '{name}' not found")
    logger.info("Disconnecting connector %s for user=%s", name, current_user.get("id"))
    # Placeholder: delete from connector_tokens table
    return {"message": f"Disconnected {connector.label}"}
