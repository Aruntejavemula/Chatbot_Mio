"""Rate limiter service - handles request rate limiting."""


class RateLimiter:
    """Service for rate limiting API requests."""

    def __init__(self, redis_url: str, redis_token: str) -> None:
        """Initialize rate limiter with Redis connection details."""
        self.redis_url = redis_url
        self.redis_token = redis_token

    async def is_rate_limited(self, key: str, limit: int, window: int) -> bool:
        """Check if a key has exceeded the rate limit."""
        pass

    async def increment(self, key: str, window: int) -> int:
        """Increment the request count for a key."""
        pass
