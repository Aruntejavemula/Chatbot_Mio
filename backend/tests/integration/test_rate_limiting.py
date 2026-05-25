"""Integration tests for rate limiting middleware."""
import pytest
from httpx import AsyncClient, ASGITransport

from app.main import app
from app.middleware.rate_limit import _rate_limiter


@pytest.fixture(autouse=True)
def reset_rate_limiter():
    """Reset the rate limiter state before each test."""
    _rate_limiter._requests.clear()
    yield
    _rate_limiter._requests.clear()


@pytest.mark.asyncio
async def test_rate_limit_exceeded_returns_429():
    """Test that exceeding rate limit returns 429."""
    transport = ASGITransport(app=app)
    token = "validtoken1234567890"
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        # The list projects endpoint has a rate limit of 30/60s
        # Make 31 requests to exceed the limit
        responses = []
        for _ in range(31):
            resp = await client.get("/projects/", headers=headers)
            responses.append(resp)

    # The last response should be 429 (rate limited)
    assert responses[-1].status_code == 429
    assert "Rate limit exceeded" in responses[-1].json()["detail"]


@pytest.mark.asyncio
async def test_within_rate_limit_succeeds():
    """Test that requests within rate limit succeed."""
    transport = ASGITransport(app=app)
    token = "anothervalidtoken12345"
    headers = {"Authorization": f"Bearer {token}"}

    async with AsyncClient(transport=transport, base_url="http://test") as client:
        response = await client.get("/projects/", headers=headers)

    # Should get 403 (not pro) but NOT 429 (rate limited)
    assert response.status_code == 403
