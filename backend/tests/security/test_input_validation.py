"""Security tests for input validation."""
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


VALID_HEADERS = {"Authorization": "Bearer validtoken1234567890"}


@pytest.mark.asyncio
async def test_invalid_hex_color_rejected():
    """Test that an invalid hex color is rejected with 422."""
    transport = ASGITransport(app=app)
    payload = {"name": "Test", "color": "not-a-color"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/projects/",
            json=payload,
            headers=VALID_HEADERS,
        )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_name_too_long_rejected():
    """Test that a name exceeding max length is rejected with 422."""
    transport = ASGITransport(app=app)
    payload = {"name": "x" * 101, "color": "#CC5801"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/projects/",
            json=payload,
            headers=VALID_HEADERS,
        )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_system_prompt_too_long_rejected():
    """Test that a system_prompt exceeding max length is rejected with 422."""
    transport = ASGITransport(app=app)
    payload = {"name": "Test", "color": "#CC5801", "system_prompt": "x" * 5001}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/projects/",
            json=payload,
            headers=VALID_HEADERS,
        )

    assert response.status_code == 422


@pytest.mark.asyncio
async def test_empty_name_rejected():
    """Test that an empty name is rejected with 422."""
    transport = ASGITransport(app=app)
    payload = {"name": "", "color": "#CC5801"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.post(
            "/projects/",
            json=payload,
            headers=VALID_HEADERS,
        )

    assert response.status_code == 422
