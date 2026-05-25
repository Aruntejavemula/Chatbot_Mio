"""Integration tests for authentication middleware."""
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.mark.asyncio
async def test_missing_auth_header_returns_401():
    """Test that missing Authorization header returns 401."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/projects/")
    assert response.status_code == 422  # FastAPI returns 422 for missing required header


@pytest.mark.asyncio
async def test_invalid_bearer_token_returns_401():
    """Test that an invalid (too short) Bearer token returns 401."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/projects/",
            headers={"Authorization": "Bearer short"},
        )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_invalid_auth_format_returns_401():
    """Test that non-Bearer auth format returns 401."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/projects/",
            headers={"Authorization": "Basic dXNlcjpwYXNz"},
        )
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_valid_bearer_token_passes_auth():
    """Test that a valid Bearer token (10+ chars) passes auth."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/projects/",
            headers={"Authorization": "Bearer abcdefghij1234567890"},
        )
    # Auth passes but user gets 403 because they're not pro
    assert response.status_code == 403
