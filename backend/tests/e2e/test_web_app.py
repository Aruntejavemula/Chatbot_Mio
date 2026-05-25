"""E2E tests for the web application."""
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.mark.e2e
@pytest.mark.asyncio
async def test_health_endpoint_e2e():
    """E2E test: health endpoint returns ok."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/health")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}


@pytest.mark.e2e
@pytest.mark.asyncio
async def test_api_docs_accessible():
    """E2E test: API docs page (/docs) is accessible."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/docs")
    assert response.status_code == 200
    assert "text/html" in response.headers.get("content-type", "")


@pytest.mark.e2e
@pytest.mark.asyncio
async def test_openapi_json_accessible():
    """E2E test: OpenAPI JSON schema is accessible."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/openapi.json")
    assert response.status_code == 200
    data = response.json()
    assert "paths" in data
    assert "/health" in data["paths"]
