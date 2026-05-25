"""Google Drive connector for file access."""

import logging
from typing import Any

import httpx

from app.services.connectors.base_connector import BaseConnector

logger = logging.getLogger(__name__)

DRIVE_API_BASE = "https://www.googleapis.com/drive/v3"


class GoogleDriveConnector(BaseConnector):
    """Access Google Drive files."""

    name = "google_drive"
    label = "Google Drive"
    description = "Search and read files from Google Drive"
    auth_type = "oauth2"
    scopes = ["https://www.googleapis.com/auth/drive.readonly"]

    async def get_tools(self, access_token: str) -> list[dict[str, Any]]:
        """Return Google Drive tool definitions."""
        return [
            {
                "type": "function",
                "function": {
                    "name": "google_drive_search",
                    "description": "Search for files in Google Drive",
                    "parameters": {
                        "type": "object",
                        "properties": {
                            "query": {"type": "string", "description": "Search query"},
                        },
                        "required": ["query"],
                    },
                },
            },
            {
                "type": "function",
                "function": {
                    "name": "google_drive_list_recent",
                    "description": "List recently modified files",
                    "parameters": {"type": "object", "properties": {}},
                },
            },
        ]

    async def execute_tool(
        self, tool_name: str, params: dict[str, Any], access_token: str
    ) -> dict[str, Any]:
        """Execute a Google Drive tool."""
        try:
            headers = {"Authorization": f"Bearer {access_token}"}
            async with httpx.AsyncClient(timeout=30.0) as client:
                if tool_name == "google_drive_search":
                    query = params.get("query", "")
                    response = await client.get(
                        f"{DRIVE_API_BASE}/files",
                        headers=headers,
                        params={"q": f"name contains '{query}'", "pageSize": "10"},
                    )
                    if response.status_code == 200:
                        return response.json()
                    return {"error": f"Drive API error: {response.status_code}"}
                elif tool_name == "google_drive_list_recent":
                    response = await client.get(
                        f"{DRIVE_API_BASE}/files",
                        headers=headers,
                        params={"orderBy": "modifiedTime desc", "pageSize": "10"},
                    )
                    if response.status_code == 200:
                        return response.json()
                    return {"error": f"Drive API error: {response.status_code}"}
            return {"error": f"Unknown tool: {tool_name}"}
        except Exception as e:
            logger.error("Google Drive tool error: %s", str(e))
            return {"error": str(e)}
