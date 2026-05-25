"""Rate limiter service - request rate limiting using Upstash Redis."""

import logging
import time
from typing import Any

from fastapi import HTTPException, Request

from app.config import get_settings

logger = logging.getLogger(__name__)


class RateLimiter:
    """Service for rate limiting API requests using sliding window."""

    LIMITS = {
        "auth": {"requests": 5, "window": 60},
        "chat": {"requests": 10, "window": 60},
        "payment": {"requests": 3, "window": 60},
        "keys": {"requests": 20, "window": 60},
        "general": {"requests": 60, "window": 60},
        "providers": {"requests": 30, "window": 60},
    }

    def __init__(self) -> None:
        """Initialize rate limiter with Upstash Redis connection."""
        self._redis = None

    async def _get_redis(self) -> Any:
        """Lazy-load Redis client."""
        if self._redis is None:
            try:
                from upstash_redis.asyncio import Redis
                settings = get_settings()
                self._redis = Redis(
                    url=settings.UPSTASH_REDIS_URL,
                    token=settings.UPSTASH_REDIS_TOKEN,
                )
            except Exception as e:
                logger.error(f"Failed to connect to Redis: {str(e)}")
                return None
        return self._redis

    async def check_rate_limit(
        self,
        identifier: str,
        limit_type: str = "general",
    ) -> tuple[bool, dict]:
        """
        Check if identifier has exceeded rate limit.

        Uses sliding window algorithm with Redis sorted sets.

        Args:
            identifier: User ID or IP address
            limit_type: Type of limit to apply

        Returns:
            Tuple of (allowed: bool, info: dict)
        """
        redis = await self._get_redis()
        if redis is None:
            # Fail open if Redis unavailable
            return True, {"allowed": True, "limit": 0, "remaining": 0, "reset": 0}

        config = self.LIMITS.get(limit_type, self.LIMITS["general"])
        limit = config["requests"]
        window = config["window"]

        key = f"rate:{limit_type}:{identifier}"
        now = int(time.time())
        window_start = now - window

        try:
            # Remove old entries, add current, count, set expiry
            await redis.zremrangebyscore(key, 0, window_start)
            await redis.zadd(key, {str(now): now})
            count = await redis.zcard(key)
            await redis.expire(key, window)

            remaining = max(0, limit - count)
            reset_time = now + window

            if count > limit:
                return False, {
                    "allowed": False,
                    "limit": limit,
                    "remaining": 0,
                    "reset": reset_time,
                    "retry_after": window,
                }

            return True, {
                "allowed": True,
                "limit": limit,
                "remaining": remaining,
                "reset": reset_time,
            }
        except Exception as e:
            logger.error(f"Rate limit check error: {str(e)}")
            return True, {"allowed": True, "limit": limit, "remaining": limit, "reset": 0}

    def get_limiter_dependency(self, limit_type: str):
        """
        Returns a FastAPI dependency function for a specific limit type.

        Raises 429 if limit exceeded.
        Uses user_id if authenticated, falls back to IP.
        """
        rate_limiter_instance = self

        async def limiter(request: Request) -> dict:
            """Rate limit dependency."""
            identifier = getattr(request.state, "user_id", None)
            if not identifier:
                identifier = request.client.host if request.client else "unknown"

            allowed, info = await rate_limiter_instance.check_rate_limit(
                identifier, limit_type
            )

            if not allowed:
                raise HTTPException(
                    status_code=429,
                    detail={
                        "message": "Too many requests. Please wait a moment and try again.",
                        "retry_after": info.get("retry_after", 60),
                    },
                    headers={
                        "Retry-After": str(info.get("retry_after", 60)),
                        "X-RateLimit-Limit": str(info.get("limit", 0)),
                        "X-RateLimit-Remaining": "0",
                        "X-RateLimit-Reset": str(info.get("reset", 0)),
                    },
                )

            return info

        return limiter


rate_limiter = RateLimiter()
