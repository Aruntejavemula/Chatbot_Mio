"""Utility helpers - token abuse detection, circuit breaker, safe logging."""

import hashlib
import logging
import time
import uuid
from typing import Any, Optional

from app.config import get_settings

logger = logging.getLogger(__name__)


async def check_token_abuse(
    user_id: str,
    tokens_used: int,
    redis_client: Any,
) -> bool:
    """
    Check for token abuse patterns.

    Tracks hourly token usage. Flags suspicious at 50K, suspends at 100K.

    Args:
        user_id: User ID
        tokens_used: Tokens consumed in this request
        redis_client: Redis client instance

    Returns:
        True if abuse detected, False otherwise
    """
    if not redis_client:
        return False

    try:
        hour = int(time.time()) // 3600
        key = f"hourly_tokens:{user_id}:{hour}"

        current = await redis_client.incrby(key, tokens_used)
        await redis_client.expire(key, 3600)

        if current > 100000:
            # Suspend token access for 1 hour
            await redis_client.set(f"token_suspended:{user_id}", "1", ex=3600)
            logger.warning(f"Token access suspended for user {user_id}: {current} tokens in 1 hour")
            await send_admin_alert(
                "Token abuse - account suspended",
                f"User {user_id} consumed {current} tokens in 1 hour. Access suspended.",
            )
            return True

        elif current > 50000:
            # Flag as suspicious
            await redis_client.set(f"suspicious:{user_id}", "1", ex=86400)
            logger.warning(f"Suspicious token usage for user {user_id}: {current} tokens in 1 hour")
            return False

        return False

    except Exception as e:
        logger.error(f"Error checking token abuse: {str(e)}")
        return False


class CircuitBreaker:
    """
    Circuit breaker for AI providers.

    States: closed (normal), open (blocking), half-open (testing).
    Opens after 5 failures in 1 minute. Retries after 30 seconds.
    """

    FAILURE_THRESHOLD = 5
    FAILURE_WINDOW = 60  # seconds
    RECOVERY_TIMEOUT = 30  # seconds

    def __init__(self, redis_client: Any = None) -> None:
        """Initialize circuit breaker."""
        self._redis = redis_client

    async def _get_redis(self) -> Any:
        """Get or create Redis client."""
        if self._redis is None:
            try:
                from upstash_redis.asyncio import Redis
                settings = get_settings()
                self._redis = Redis(
                    url=settings.UPSTASH_REDIS_URL,
                    token=settings.UPSTASH_REDIS_TOKEN,
                )
            except Exception:
                return None
        return self._redis

    async def is_open(self, provider: str) -> bool:
        """
        Check if circuit is open (blocking requests) for a provider.

        Args:
            provider: AI provider name

        Returns:
            True if circuit is open (should NOT call provider)
        """
        redis = await self._get_redis()
        if not redis:
            return False

        try:
            state = await redis.get(f"circuit:{provider}:state")
            if state == "open":
                # Check if recovery timeout has passed
                last_failure = await redis.get(f"circuit:{provider}:last_failure")
                if last_failure:
                    elapsed = time.time() - float(last_failure)
                    if elapsed >= self.RECOVERY_TIMEOUT:
                        # Move to half-open
                        await redis.set(f"circuit:{provider}:state", "half-open", ex=60)
                        return False
                return True
            return False
        except Exception as e:
            logger.error(f"Circuit breaker check error: {str(e)}")
            return False

    async def record_failure(self, provider: str) -> None:
        """
        Record a failure for a provider.

        Args:
            provider: AI provider that failed
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            fail_key = f"circuit:{provider}:failures"
            count = await redis.incr(fail_key)
            await redis.expire(fail_key, self.FAILURE_WINDOW)

            if count >= self.FAILURE_THRESHOLD:
                await redis.set(f"circuit:{provider}:state", "open", ex=self.RECOVERY_TIMEOUT + 10)
                await redis.set(f"circuit:{provider}:last_failure", str(time.time()), ex=self.RECOVERY_TIMEOUT + 10)
                logger.warning(f"Circuit opened for provider: {provider}")
        except Exception as e:
            logger.error(f"Circuit breaker record error: {str(e)}")

    async def record_success(self, provider: str) -> None:
        """
        Record a success for a provider. Closes circuit if half-open.

        Args:
            provider: AI provider that succeeded
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            state = await redis.get(f"circuit:{provider}:state")
            if state in ("half-open", "open"):
                await redis.delete(f"circuit:{provider}:state")
                await redis.delete(f"circuit:{provider}:failures")
                await redis.delete(f"circuit:{provider}:last_failure")
                logger.info(f"Circuit closed for provider: {provider}")
        except Exception as e:
            logger.error(f"Circuit breaker success error: {str(e)}")


async def send_admin_alert(subject: str, message: str) -> None:
    """
    Send alert email to admin for critical security events.

    Args:
        subject: Alert subject
        message: Alert message body
    """
    try:
        from app.services.email_service import email_service
        import resend

        settings = get_settings()
        admin_email = "admin@yourdomain.com"  # Configure via env

        resend.Emails.send({
            "from": "Mio Alerts <alerts@yourdomain.com>",
            "to": admin_email,
            "subject": f"[Mio Alert] {subject}",
            "html": f"<h3>{subject}</h3><p>{message}</p><p>Time: {time.strftime('%Y-%m-%d %H:%M:%S UTC')}</p>",
        })
        logger.info(f"Admin alert sent: {subject}")
    except Exception as e:
        logger.error(f"Failed to send admin alert: {str(e)}")


def validate_uuid(value: str) -> bool:
    """
    Validate that a string is a valid UUID.

    Args:
        value: String to validate

    Returns:
        True if valid UUID, False otherwise
    """
    try:
        uuid.UUID(value)
        return True
    except (ValueError, AttributeError):
        return False


def safe_log(data: dict) -> dict:
    """
    Remove sensitive fields before logging.

    Args:
        data: Dict to sanitize for logging

    Returns:
        Cleaned dict with sensitive values replaced by [REDACTED]
    """
    sensitive_fields = {
        "api_key", "encrypted_key", "iv", "raw_key",
        "token", "password", "secret", "stripe_customer_id",
        "card_number", "stripe_secret_key", "razorpay_key_secret",
        "encryption_secret", "id_token", "identity_token",
    }

    cleaned = {}
    for key, value in data.items():
        if key.lower() in sensitive_fields:
            cleaned[key] = "[REDACTED]"
        elif isinstance(value, dict):
            cleaned[key] = safe_log(value)
        else:
            cleaned[key] = value

    return cleaned


circuit_breaker = CircuitBreaker()

# --- Cost tracking for money protection ---

COST_PER_TOKEN = {
    "deepseek": {"input": 0.00000027, "output": 0.0000011},
    "kimi": {"input": 0.00000015, "output": 0.0000060},
    "gemini-flash": {"input": 0.000000075, "output": 0.0000003},
    "default": {"input": 0.000001, "output": 0.000002},
}


async def track_spending(
    user_id: str,
    model: str,
    input_tokens: int,
    output_tokens: int,
    redis_client,
) -> tuple[float, bool]:
    """
    Track estimated USD spending per user per day.
    Soft alert at $2/day. Hard block at $5/day.

    Args:
        user_id: User ID
        model: Model name for cost lookup
        input_tokens: Input tokens consumed
        output_tokens: Output tokens consumed
        redis_client: Redis client

    Returns:
        Tuple of (total_spent_today, is_blocked)
    """
    if not redis_client:
        return 0.0, False

    try:
        from datetime import date as date_type
        today = date_type.today().isoformat()

        # Find matching cost rate
        rates = COST_PER_TOKEN.get("default")
        for key in COST_PER_TOKEN:
            if key in model.lower():
                rates = COST_PER_TOKEN[key]
                break

        cost = input_tokens * rates["input"] + output_tokens * rates["output"]

        key = f"spending:{user_id}:{today}"
        new_total_str = await redis_client.incrbyfloat(key, cost)
        await redis_client.expire(key, 86400)
        new_total = float(new_total_str)

        if new_total >= 5.0:
            await redis_client.set(f"cost_blocked:{user_id}", "1", ex=86400)
            await send_admin_alert(
                f"User {user_id} cost blocked",
                f"Spent ${new_total:.4f} today. Blocked.",
            )
            return new_total, True

        if new_total >= 2.0:
            await send_admin_alert(
                f"User {user_id} high spending",
                f"Spent ${new_total:.4f} today. Monitoring.",
            )

        return new_total, False

    except Exception as e:
        logger.error(f"Error tracking spending: {str(e)}")
        return 0.0, False


async def check_cost_blocked(user_id: str, redis_client) -> bool:
    """
    Check if user is cost blocked. Called before every AI request.

    Args:
        user_id: User ID
        redis_client: Redis client

    Returns:
        True if blocked, False otherwise
    """
    if not redis_client:
        return False
    try:
        blocked = await redis_client.get(f"cost_blocked:{user_id}")
        return blocked is not None
    except Exception:
        return False


async def get_cached_subscription(
    user_id: str,
    redis_client,
    supabase_client,
) -> dict:
    """
    Get subscription with Redis caching (5 minute TTL).
    Prevents DB hit on every request.

    Args:
        user_id: User ID
        redis_client: Redis client
        supabase_client: Supabase client

    Returns:
        Subscription dict
    """
    import json

    if redis_client:
        try:
            cache_key = f"sub_status:{user_id}"
            cached = await redis_client.get(cache_key)
            if cached:
                return json.loads(cached)
        except Exception:
            pass

    try:
        result = (
            supabase_client.table("subscriptions")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        if result.data:
            sub = result.data[0]
            if redis_client:
                try:
                    await redis_client.set(
                        f"sub_status:{user_id}",
                        json.dumps(sub),
                        ex=300,
                    )
                except Exception:
                    pass
            return sub
    except Exception as e:
        logger.error(f"Error getting subscription: {str(e)}")

    return {"plan": "free", "status": "active", "country_bucket": "premium"}


async def invalidate_subscription_cache(user_id: str, redis_client) -> None:
    """
    Invalidate subscription cache. Call in payment webhooks.

    Args:
        user_id: User ID
        redis_client: Redis client
    """
    if redis_client:
        try:
            await redis_client.delete(f"sub_status:{user_id}")
        except Exception:
            pass
