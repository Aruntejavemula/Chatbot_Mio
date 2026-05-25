"""Message guard service for enforcing daily message limits on free plans.

Production uses Upstash Redis for distributed counting.
This implementation uses in-memory storage suitable for
single-instance development and testing.
"""
from __future__ import annotations

import logging
import time
from datetime import date, datetime, timezone

logger = logging.getLogger(__name__)

# Free plan limits
FREE_DAILY_MESSAGE_LIMIT: int = 20
FREE_MESSAGE_WARNING: int = 15

# Cleanup interval in seconds (1 hour)
_CLEANUP_INTERVAL: int = 3600


class MessageGuard:
    """Enforces daily message limits for free-plan users.

    Uses an in-memory dict as a Redis placeholder. In production,
    this would use Upstash Redis with TTL-based key expiration.
    """

    def __init__(self) -> None:
        """Initialize the message guard with an empty counter store."""
        self._counts: dict[str, int] = {}
        self._last_cleanup: float = 0.0

    def _cleanup_old_keys(self) -> None:
        """Remove keys for dates older than today.

        Only runs if at least _CLEANUP_INTERVAL seconds have passed
        since the last cleanup to avoid overhead on every request.
        """
        now = time.time()
        if now - self._last_cleanup < _CLEANUP_INTERVAL:
            return

        self._last_cleanup = now
        today_str = date.today().isoformat()
        stale_keys = [
            key for key in self._counts
            if not key.endswith(f":{today_str}")
        ]
        for key in stale_keys:
            del self._counts[key]

        if stale_keys:
            logger.debug(
                "MessageGuard cleanup removed %d stale keys", len(stale_keys)
            )

    def _get_key(self, user_id: str) -> str:
        """Build the storage key for today's message count.

        Args:
            user_id: The user identifier.

        Returns:
            A string key in the format msg_count:{user_id}:{date}.
        """
        today = date.today().isoformat()
        return f"msg_count:{user_id}:{today}"

    def check_message_limit(self, user_id: str, plan: str) -> dict:
        """Check whether a user is allowed to send another message.

        If the user's plan is not "free", they are always allowed.
        Otherwise, checks the daily count against FREE_DAILY_MESSAGE_LIMIT.

        Args:
            user_id: The user identifier.
            plan: The user's subscription plan (e.g., "free", "pro").

        Returns:
            A dict with keys: allowed, current_count, limit, remaining, warning.
        """
        self._cleanup_old_keys()

        if plan != "free":
            return {
                "allowed": True,
                "current_count": 0,
                "limit": FREE_DAILY_MESSAGE_LIMIT,
                "remaining": FREE_DAILY_MESSAGE_LIMIT,
                "warning": False,
            }

        key = self._get_key(user_id)
        current_count = self._counts.get(key, 0)
        allowed = current_count < FREE_DAILY_MESSAGE_LIMIT
        remaining = max(0, FREE_DAILY_MESSAGE_LIMIT - current_count)
        warning = current_count >= FREE_MESSAGE_WARNING

        logger.debug(
            "Message limit check: user=%s, count=%d, allowed=%s, warning=%s",
            user_id,
            current_count,
            allowed,
            warning,
        )

        return {
            "allowed": allowed,
            "current_count": current_count,
            "limit": FREE_DAILY_MESSAGE_LIMIT,
            "remaining": remaining,
            "warning": warning,
        }

    def increment_message_count(self, user_id: str) -> int:
        """Increment the daily message count for a user.

        In production, this would use Redis INCR with a TTL of 86400 seconds.

        Args:
            user_id: The user identifier.

        Returns:
            The new message count after incrementing.
        """
        key = self._get_key(user_id)
        current = self._counts.get(key, 0)
        self._counts[key] = current + 1

        logger.debug(
            "Message count incremented: user=%s, new_count=%d",
            user_id,
            self._counts[key],
        )

        return self._counts[key]

    def get_message_count(self, user_id: str) -> int:
        """Get the current daily message count for a user.

        Args:
            user_id: The user identifier.

        Returns:
            The current message count for today.
        """
        key = self._get_key(user_id)
        return self._counts.get(key, 0)


# Module-level instance for use across the application
message_guard = MessageGuard()
