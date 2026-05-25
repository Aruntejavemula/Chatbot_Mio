"""Integration tests for project connector endpoints."""
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.middleware.rate_limit import _rate_limiter


@pytest.fixture(autouse=True)
def reset_rate_limiter():
    """Reset the rate limiter state before each test."""
    _rate_limiter.reset()
    yield
    _rate_limiter.reset()


@pytest.mark.asyncio
async def test_projects_list_returns_403_for_non_pro():
    """Test that listing projects returns 403 for non-pro user."""
    transport = ASGITransport(app=app)
    headers = {"Authorization": "Bearer validtoken1234567890"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/projects/", headers=headers)

    assert response.status_code == 403
    assert "Pro plan" in response.json()["detail"]


@pytest.mark.asyncio
async def test_create_project_returns_403_for_non_pro():
    """Test that creating a project returns 403 for non-pro user."""
    transport = ASGITransport(app=app)
    headers = {"Authorization": "Bearer validtoken1234567890"}
    payload = {"name": "Test Project", "color": "#FF5733"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/projects/", json=payload, headers=headers)

    assert response.status_code == 403
    assert "Pro plan" in response.json()["detail"]


@pytest.mark.asyncio
async def test_create_project_requires_auth():
    """Test that creating a project requires authentication."""
    transport = ASGITransport(app=app)
    payload = {"name": "Test Project"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post("/projects/", json=payload)

    assert response.status_code == 422  # Missing required header
