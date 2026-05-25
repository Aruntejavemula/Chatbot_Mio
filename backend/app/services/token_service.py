"""Token service - handles token tracking, cap enforcement, and loading words."""

import logging
from datetime import date, datetime
from typing import Optional

logger = logging.getLogger(__name__)


class TokenService:
    """Service for managing token usage, limits, and loading words."""

    DAILY_LIMITS = {
        "free": 0,
        "basic": 0,
        "pro": 100000,
    }

    MONTHLY_LIMITS = {
        "premium": 2000000,
        "middle": 2000000,
        "value": 2000000,
    }

    MESSAGE_LIMITS = {
        "free": 20,
        "basic": 100,
        "pro": -1,
    }

    LOADING_WORDS = [
        "Cooking", "Brewing", "Bamboozling",
        "Crafting", "Thinking", "Hustling",
        "Calculating", "Figuring", "Conjuring",
        "Processing", "Scheming", "Pondering",
        "Contemplating", "Manifesting", "Engineering",
        "Vibing", "Decoding", "Untangling",
        "Simulating", "Philosophizing", "Hallucinating",
        "Overclocking", "Caffeinating", "Debugging",
        "Inventing", "Synthesizing", "Hypothesizing",
        "Daydreaming", "Theorizing",
        "Reverse engineering", "Brainstorming",
        "Speculating", "Innovating", "Deducing",
        "Encrypting", "Wrangling", "Summoning",
        "Architecting", "Channeling", "Defragmenting",
    ]

    async def check_message_limit(
        self,
        user_id: str,
        plan: str,
        redis_client,
    ) -> tuple[bool, str]:
        """
        Check if user has exceeded daily message limit.

        Args:
            user_id: User ID
            plan: User's current plan
            redis_client: Upstash Redis client

        Returns:
            Tuple of (can_send: bool, reason: str)
        """
        limit = self.MESSAGE_LIMITS.get(plan, 0)
        if limit == -1:
            return True, ""

        today = date.today().isoformat()
        redis_key = f"msg_count:{user_id}:{today}"

        try:
            count = await redis_client.get(redis_key)
            current = int(count) if count else 0

            if current >= limit:
                return False, (
                    f"Daily limit of {limit} messages reached. "
                    f"Upgrade to continue."
                )

            await redis_client.incr(redis_key)
            await redis_client.expire(redis_key, 86400)
            return True, ""
        except Exception as e:
            logger.error(f"Redis error in check_message_limit: {str(e)}")
            # Fail open - allow the message if Redis is down
            return True, ""

    async def check_token_limit(
        self,
        user_id: str,
        plan: str,
        country_bucket: str,
        redis_client,
        supabase_client,
    ) -> tuple[bool, str]:
        """
        Check if pro user has exceeded token limits.

        Only applies to pro plan users using platform tokens.
        Free and basic users use BYOK, no token limits from us.

        Args:
            user_id: User ID
            plan: User's current plan
            country_bucket: Pricing bucket for monthly limit
            redis_client: Upstash Redis client
            supabase_client: Supabase client

        Returns:
            Tuple of (can_use: bool, reason: str)
        """
        if plan != "pro":
            return True, ""

        daily_limit = self.DAILY_LIMITS.get(plan, 0)
        monthly_limit = self.MONTHLY_LIMITS.get(country_bucket, 2000000)

        today = date.today().isoformat()

        try:
            # Check daily limit via Redis
            daily_key = f"tokens_daily:{user_id}:{today}"
            daily_used_raw = await redis_client.get(daily_key)
            daily_count = int(daily_used_raw) if daily_used_raw else 0

            if daily_count >= daily_limit:
                return False, (
                    "Daily token limit of 100,000 reached. "
                    "Resets tomorrow. Use your own API key to continue."
                )

            # Check monthly limit via Supabase
            month = today[:7]
            result = (
                supabase_client.table("token_usage")
                .select("tokens_used_input, tokens_used_output")
                .eq("user_id", user_id)
                .eq("month", month)
                .execute()
            )

            monthly_used = sum(
                row["tokens_used_input"] + row["tokens_used_output"]
                for row in result.data
            ) if result.data else 0

            if monthly_used >= monthly_limit:
                return False, (
                    "Monthly token limit reached. "
                    "Resets on the 1st. Use your own API key to continue."
                )

            return True, ""
        except Exception as e:
            logger.error(f"Error in check_token_limit: {str(e)}")
            return True, ""

    async def track_usage(
        self,
        user_id: str,
        input_tokens: int,
        output_tokens: int,
        model: str,
        redis_client,
        supabase_client,
    ) -> None:
        """
        Track token usage after AI response.

        Updates Redis daily counter and upserts Supabase token_usage table.

        Args:
            user_id: User ID
            input_tokens: Number of input tokens consumed
            output_tokens: Number of output tokens consumed
            model: Model that consumed the tokens
            redis_client: Upstash Redis client
            supabase_client: Supabase client
        """
        today = date.today().isoformat()
        month = today[:7]
        total = input_tokens + output_tokens

        try:
            # Update Redis daily counter
            daily_key = f"tokens_daily:{user_id}:{today}"
            await redis_client.incrby(daily_key, total)
            await redis_client.expire(daily_key, 86400)
        except Exception as e:
            logger.error(f"Redis error in track_usage: {str(e)}")

        try:
            # Upsert Supabase token_usage
            existing = (
                supabase_client.table("token_usage")
                .select("id, tokens_used_input, tokens_used_output")
                .eq("user_id", user_id)
                .eq("date", today)
                .execute()
            )

            if existing.data:
                row = existing.data[0]
                supabase_client.table("token_usage").update({
                    "tokens_used_input": row["tokens_used_input"] + input_tokens,
                    "tokens_used_output": row["tokens_used_output"] + output_tokens,
                    "model_used": model,
                }).eq("id", row["id"]).execute()
            else:
                supabase_client.table("token_usage").insert({
                    "user_id": user_id,
                    "date": today,
                    "month": month,
                    "tokens_used_input": input_tokens,
                    "tokens_used_output": output_tokens,
                    "model_used": model,
                }).execute()
        except Exception as e:
            logger.error(f"Supabase error in track_usage: {str(e)}")

    async def get_usage_summary(
        self,
        user_id: str,
        plan: str,
        country_bucket: str,
        redis_client,
        supabase_client,
    ) -> dict:
        """
        Get complete token usage summary for user.

        Args:
            user_id: User ID
            plan: User's current plan
            country_bucket: Pricing bucket
            redis_client: Upstash Redis client
            supabase_client: Supabase client

        Returns:
            Dict with daily/monthly usage, limits, model, and reset time
        """
        today = date.today().isoformat()
        month = today[:7]

        # Daily usage from Redis
        daily_used = 0
        try:
            daily_key = f"tokens_daily:{user_id}:{today}"
            daily_used_raw = await redis_client.get(daily_key)
            daily_used = int(daily_used_raw) if daily_used_raw else 0
        except Exception as e:
            logger.error(f"Redis error in get_usage_summary: {str(e)}")

        # Monthly usage from Supabase
        monthly_used = 0
        current_model = "DeepSeek V3"
        try:
            result = (
                supabase_client.table("token_usage")
                .select("tokens_used_input, tokens_used_output, model_used")
                .eq("user_id", user_id)
                .eq("month", month)
                .execute()
            )
            if result.data:
                monthly_used = sum(
                    r["tokens_used_input"] + r["tokens_used_output"]
                    for r in result.data
                )
                current_model = result.data[-1].get("model_used", "DeepSeek V3")
        except Exception as e:
            logger.error(f"Supabase error in get_usage_summary: {str(e)}")

        daily_limit = self.DAILY_LIMITS.get(plan, 0)
        monthly_limit = self.MONTHLY_LIMITS.get(country_bucket, 2000000)

        # Calculate next reset time (1st of next month)
        now = datetime.now()
        if now.month == 12:
            next_month = now.replace(year=now.year + 1, month=1, day=1,
                                     hour=0, minute=0, second=0, microsecond=0)
        else:
            next_month = now.replace(month=now.month + 1, day=1,
                                     hour=0, minute=0, second=0, microsecond=0)

        return {
            "daily_used": daily_used,
            "daily_limit": daily_limit,
            "monthly_used": monthly_used,
            "monthly_limit": monthly_limit,
            "current_model": current_model,
            "reset_time": next_month.isoformat(),
            "can_use_our_tokens": plan == "pro",
        }

    def get_next_loading_word(self, current_index: int) -> tuple[str, int]:
        """
        Get next loading word in sequence.

        Args:
            current_index: Current word index

        Returns:
            Tuple of (word, next_index)
        """
        word = self.LOADING_WORDS[current_index % 40]
        next_index = (current_index + 1) % 40
        return word, next_index
