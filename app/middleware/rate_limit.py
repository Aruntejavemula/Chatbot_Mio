"""Rate limiting middleware for API endpoints.

Production uses Upstash Redis for distributed rate limiting.
This implementation uses in-memory storage suitable for
single-instance development and testing.
"""

import logging
import time
from typing import Any, Callable

from fastapi import Depends, HTTPException, Request

logger = logging.getLogger(__name__)


class RateLimiter:
    """In-memory rate limiter using sliding window.

    Production uses Upstash Redis for distributed rate limiting
    across multiple instances. This in-memory implementation is
    suitable for development and single-instance deployments.
    """

    def __init__(self) -> None:
        """Initialize the rate limiter with an empty request store."""
        self._requests: dict[str, list[float]] = {}

    def _cleanup_expired(self, key: str, window_seconds: int) -> None:
        """Remove expired timestamps from the request store.

        Args:
            key: The rate limit key to clean up.
            window_seconds: The time window in seconds.
        """
        now = time.time()
        cutoff = now - window_seconds
        if key in self._requests:
            self._requests[key] = [
                ts for ts in self._requests[key] if ts > cutoff
            ]

    def check_rate_limit(
        self, key: str, max_requests: int, window_seconds: int
    ) -> bool:
        """Check if a request is within the rate limit.

        Args:
            key: The unique key for rate limiting (e.g., user_id).
            max_requests: Maximum number of requests allowed.
            window_seconds: The time window in seconds.

        Returns:
            True if the request is allowed, False if rate limited.
        """
        self._cleanup_expired(key, window_seconds)

        if key not in self._requests:
            self._requests[key] = []

        if len(self._requests[key]) >= max_requests:
            return False

        self._requests[key].append(time.time())
        return True


# Global rate limiter instance
_rate_limiter = RateLimiter()


def rate_limit(
    max_requests: int, window_seconds: int
) -> Callable[..., Any]:
    """Create a rate limit dependency for FastAPI endpoints.

    Args:
        max_requests: Maximum number of requests allowed in the window.
        window_seconds: The time window in seconds.

    Returns:
        A FastAPI dependency function that enforces the rate limit.
    """

    async def _rate_limit_dependency(request: Request) -> None:
        """Enforce rate limiting on the request.

        Args:
            request: The incoming FastAPI request.

        Raises:
            HTTPException: If the rate limit is exceeded (429).
        """
        # Use client IP as fallback, prefer user_id if available
        client_ip = request.client.host if request.client else "unknown"
        key = f"rate_limit:{client_ip}"

        if not _rate_limiter.check_rate_limit(key, max_requests, window_seconds):
            logger.warning(
                "Rate limit exceeded for key=%s (limit=%d/%ds)",
                key,
                max_requests,
                window_seconds,
            )
            raise HTTPException(
                status_code=429,
                detail="Rate limit exceeded. Please try again later.",
            )

    return _rate_limit_dependency
