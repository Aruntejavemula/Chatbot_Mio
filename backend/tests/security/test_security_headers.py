"""Security tests for CORS headers."""
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app


@pytest.mark.asyncio
async def test_cors_headers_present():
    """Test that CORS headers are present on responses."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/health",
            headers={"Origin": "http://localhost:3000"},
        )

    assert response.status_code == 200
    assert "access-control-allow-origin" in response.headers


@pytest.mark.asyncio
async def test_cors_preflight_options():
    """Test that OPTIONS preflight request is handled."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.options(
            "/health",
            headers={
                "Origin": "http://localhost:3000",
                "Access-Control-Request-Method": "GET",
                "Access-Control-Request-Headers": "Authorization",
            },
        )

    assert response.status_code == 200
    assert "access-control-allow-origin" in response.headers
    assert "access-control-allow-methods" in response.headers


@pytest.mark.asyncio
async def test_cors_disallowed_origin():
    """Test that disallowed origins do not get CORS headers."""
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get(
            "/health",
            headers={"Origin": "http://evil.com"},
        )

    assert response.status_code == 200
    # Disallowed origin should not get access-control-allow-origin
    allow_origin = response.headers.get("access-control-allow-origin")
    assert allow_origin != "http://evil.com"
