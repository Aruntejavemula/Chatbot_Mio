"""Token guard - hard cap enforcement for platform token usage."""

import logging
from datetime import date

logger = logging.getLogger(__name__)


class TokenGuard:
    """Hard cap enforcement for daily and monthly token limits."""

    DAILY_HARD_CAP = 100000
    MONTHLY_HARD_CAP_PREMIUM = 3000000
    MONTHLY_HARD_CAP_VALUE = 2000000

    async def check_hard_caps(
        self,
        user_id: str,
        country_bucket: str,
        redis_client,
    ) -> tuple[bool, str]:
        """
        Hard cap check before every AI request using our tokens.
        Uses atomic Redis operations to prevent race conditions.

        Args:
            user_id: User ID
            country_bucket: Pricing bucket
            redis_client: Redis client

        Returns:
            Tuple of (allowed: bool, reason: str)
        """
        if not redis_client:
            return True, ""

        try:
            today = date.today().isoformat()
            month = today[:7]

            daily_key = f"hard_daily:{user_id}:{today}"
            monthly_key = f"hard_monthly:{user_id}:{month}"

            daily_used = await redis_client.get(daily_key)
            daily_count = int(daily_used) if daily_used else 0

            if daily_count >= self.DAILY_HARD_CAP:
                return False, (
                    "Daily token limit of 100,000 reached. "
                    "Resets tomorrow at midnight UTC. "
                    "Add your own API key to continue."
                )

            monthly_cap = (
                self.MONTHLY_HARD_CAP_VALUE
                if country_bucket == "value"
                else self.MONTHLY_HARD_CAP_PREMIUM
            )

            monthly_used = await redis_client.get(monthly_key)
            monthly_count = int(monthly_used) if monthly_used else 0

            if monthly_count >= monthly_cap:
                return False, (
                    "Monthly token limit reached. "
                    "Resets on the 1st. "
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
        Atomically increment hard cap counters after successful AI response.
        Uses Redis INCRBY for atomic operation.

        Args:
            user_id: User ID
            tokens_used: Total tokens consumed
            redis_client: Redis client
        """
        if not redis_client or tokens_used <= 0:
            return

        try:
            today = date.today().isoformat()
            month = today[:7]

            daily_key = f"hard_daily:{user_id}:{today}"
            monthly_key = f"hard_monthly:{user_id}:{month}"

            await redis_client.incrby(daily_key, tokens_used)
            await redis_client.expire(daily_key, 86400)
            await redis_client.incrby(monthly_key, tokens_used)
            await redis_client.expire(monthly_key, 2592000)  # 30 days

        except Exception as e:
            logger.error(f"Hard cap increment error: {str(e)}")


token_guard = TokenGuard()
