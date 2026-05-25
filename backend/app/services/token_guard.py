"""Token guard - hard cap enforcement for platform token usage."""

import logging
from datetime import date

from app.utils.constants import (
    DAILY_TOKEN_CAP,
    FIVE_HOUR_TOKEN_CAP,
    MONTHLY_TOKEN_CAP,
    WEEKLY_TOKEN_CAP,
)

logger = logging.getLogger(__name__)


class TokenGuard:
    """Hard cap enforcement for 5-hour, daily, weekly, and monthly token limits."""

    async def check_hard_caps(
        self,
        user_id: str,
        redis_client,
    ) -> tuple[bool, str]:
        """
        Hard cap check before every AI request using our tokens.
        Checks all 4 limits in order: 5-hour, daily, weekly, monthly.

        Args:
            user_id: User ID
            redis_client: Redis client

        Returns:
            Tuple of (allowed: bool, reason: str)
        """
        if not redis_client:
            return True, ""

        try:
            today = date.today()
            today_str = today.isoformat()
            year = today.year
            week = today.isocalendar()[1]
            month = today.month

            # Determine 5-hour block (0-4 based on hour)
            from datetime import datetime
            current_hour = datetime.utcnow().hour
            block = current_hour // 5

            # Check 5-hour cap
            five_hour_key = f"five_hour:{user_id}:{today_str}:{block}"
            five_hour_used = await redis_client.get(five_hour_key)
            five_hour_count = int(five_hour_used) if five_hour_used else 0

            if five_hour_count >= FIVE_HOUR_TOKEN_CAP:
                return False, (
                    "5-hour limit reached (40K tokens). "
                    "Add your own API key to continue."
                )

            # Check daily cap
            daily_key = f"daily:{user_id}:{today_str}"
            daily_used = await redis_client.get(daily_key)
            daily_count = int(daily_used) if daily_used else 0

            if daily_count >= DAILY_TOKEN_CAP:
                return False, (
                    "Daily limit reached (100K tokens). "
                    "Add your own API key to continue."
                )

            # Check weekly cap
            weekly_key = f"weekly:{user_id}:{year}:{week}"
            weekly_used = await redis_client.get(weekly_key)
            weekly_count = int(weekly_used) if weekly_used else 0

            if weekly_count >= WEEKLY_TOKEN_CAP:
                return False, (
                    "Weekly limit reached (500K tokens). "
                    "Add your own API key to continue."
                )

            # Check monthly cap
            monthly_key = f"monthly:{user_id}:{year}:{month}"
            monthly_used = await redis_client.get(monthly_key)
            monthly_count = int(monthly_used) if monthly_used else 0

            if monthly_count >= MONTHLY_TOKEN_CAP:
                return False, (
                    "Monthly limit reached (2M tokens). "
                    "Add your own API key to continue."
                )

            return True, ""

        except Exception as e:
            logger.error(f"Hard cap check error: {str(e)}")
            return True, ""

    async def increment_hard_caps(
        self,
        user_id: str,
        tokens_used: int,
        redis_client,
    ) -> None:
        """
        Atomically increment all 4 hard cap counters after successful AI response.
        Uses Redis INCRBY for atomic operation.

        Args:
            user_id: User ID
            tokens_used: Total tokens consumed
            redis_client: Redis client
        """
        if not redis_client or tokens_used <= 0:
            return

        try:
            today = date.today()
            today_str = today.isoformat()
            year = today.year
            week = today.isocalendar()[1]
            month = today.month

            from datetime import datetime
            current_hour = datetime.utcnow().hour
            block = current_hour // 5

            # 5-hour key with TTL 18000 (5 hours)
            five_hour_key = f"five_hour:{user_id}:{today_str}:{block}"
            await redis_client.incrby(five_hour_key, tokens_used)
            await redis_client.expire(five_hour_key, 18000)

            # Daily key with TTL 86400 (24 hours)
            daily_key = f"daily:{user_id}:{today_str}"
            await redis_client.incrby(daily_key, tokens_used)
            await redis_client.expire(daily_key, 86400)

            # Weekly key with TTL 604800 (7 days)
            weekly_key = f"weekly:{user_id}:{year}:{week}"
            await redis_client.incrby(weekly_key, tokens_used)
            await redis_client.expire(weekly_key, 604800)

            # Monthly key with TTL 2592000 (30 days)
            monthly_key = f"monthly:{user_id}:{year}:{month}"
            await redis_client.incrby(monthly_key, tokens_used)
            await redis_client.expire(monthly_key, 2592000)

        except Exception as e:
            logger.error(f"Hard cap increment error: {str(e)}")


token_guard = TokenGuard()
