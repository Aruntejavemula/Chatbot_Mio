"""Security middleware - request validation, abuse detection, and protection."""

import hashlib
import logging
import time
import uuid
from typing import Any, Optional

from fastapi import HTTPException, Request

from app.config import get_settings

logger = logging.getLogger(__name__)

# Prompt injection patterns to flag (not block)
INJECTION_PATTERNS = [
    "ignore previous instructions",
    "ignore all previous",
    "you are now",
    "system prompt",
    "forget everything",
    "disregard all",
    "new instructions",
    "override your",
]

# SQL keywords that shouldn't appear in normal fields
SQL_KEYWORDS = ["DROP TABLE", "DELETE FROM", "INSERT INTO", "UPDATE SET", "UNION SELECT", "--", ";--"]


class SecurityMiddleware:
    """Handles request validation, abuse detection, and content filtering."""

    def __init__(self) -> None:
        """Initialize security middleware."""
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
                logger.error(f"Redis connection failed: {str(e)}")
                return None
        return self._redis

    async def validate_request_size(
        self, content_length: int, endpoint: str
    ) -> None:
        """
        Validate request body size based on endpoint type.

        Args:
            content_length: Size of request body in bytes
            endpoint: Request path

        Raises:
            HTTPException: 413 if body too large
        """
        if "upload" in endpoint or "file" in endpoint:
            max_size = 10 * 1024 * 1024  # 10MB
        elif "chat" in endpoint or "stream" in endpoint:
            max_size = 100 * 1024  # 100KB
        else:
            max_size = 10 * 1024  # 10KB

        if content_length > max_size:
            raise HTTPException(
                status_code=413,
                detail=f"Request body too large. Maximum: {max_size} bytes",
            )

    def sanitize_string(self, value: str) -> str:
        """
        Strip null bytes and dangerous characters from string input.

        Args:
            value: Raw input string

        Returns:
            Sanitized string
        """
        if not value:
            return value
        # Strip null bytes
        return value.replace("\x00", "").strip()

    def validate_field_lengths(self, data: dict) -> None:
        """
        Validate string field lengths.

        Args:
            data: Request body dict

        Raises:
            HTTPException: 400 if any field exceeds limit
        """
        limits = {
            "content": 10000,
            "title": 200,
            "provider": 50,
            "model": 100,
            "device_name": 200,
            "device_id": 128,
            "raw_key": 500,
        }

        for field, max_len in limits.items():
            value = data.get(field)
            if isinstance(value, str) and len(value) > max_len:
                raise HTTPException(
                    status_code=400,
                    detail=f"Field '{field}' exceeds maximum length of {max_len}",
                )

    def validate_uuid(self, value: str) -> bool:
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

    def check_sql_injection(self, data: dict) -> None:
        """
        Check for SQL injection patterns in request data.

        Args:
            data: Request body dict

        Raises:
            HTTPException: 400 if suspicious SQL found
        """
        for key, value in data.items():
            if key == "content":
                continue  # Chat content can have anything
            if isinstance(value, str):
                upper_val = value.upper()
                for keyword in SQL_KEYWORDS:
                    if keyword.upper() in upper_val:
                        logger.warning(f"SQL injection attempt in field '{key}': {value[:50]}")
                        raise HTTPException(
                            status_code=400,
                            detail="Invalid input detected",
                        )

    async def track_failed_auth(self, ip: str) -> None:
        """
        Track failed auth attempts per IP. Ban after 10 failures in 1 hour.

        Args:
            ip: Client IP address

        Raises:
            HTTPException: 403 if IP is banned
        """
        redis = await self._get_redis()
        if not redis:
            return

        ban_key = f"auth_banned:{ip}"
        fail_key = f"failed_auth:{ip}"

        try:
            # Check if already banned
            is_banned = await redis.get(ban_key)
            if is_banned:
                raise HTTPException(
                    status_code=403,
                    detail="Too many failed attempts. Try again later.",
                )

            # Increment failure count
            count = await redis.incr(fail_key)
            await redis.expire(fail_key, 3600)  # 1 hour window

            if count >= 10:
                # Ban for 24 hours
                await redis.set(ban_key, "1", ex=86400)
                logger.warning(f"IP banned for failed auth: {ip}")
                raise HTTPException(
                    status_code=403,
                    detail="Too many failed attempts. Try again in 24 hours.",
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error tracking failed auth: {str(e)}")

    async def check_account_suspended(self, user_id: str) -> None:
        """
        Check if user account is suspended.

        Args:
            user_id: User ID to check

        Raises:
            HTTPException: 403 if account suspended
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            suspended = await redis.get(f"suspended:{user_id}")
            if suspended:
                raise HTTPException(
                    status_code=403,
                    detail="Account suspended. Contact support.",
                )

            token_suspended = await redis.get(f"token_suspended:{user_id}")
            if token_suspended:
                raise HTTPException(
                    status_code=429,
                    detail="Unusual activity detected. Token access suspended for 1 hour.",
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error checking suspension: {str(e)}")

    def verify_request_headers(self, request: Request) -> None:
        """
        Verify required security headers for chat requests.

        Args:
            request: FastAPI request object

        Raises:
            HTTPException: 400 if headers missing or invalid
        """
        device_id = request.headers.get("X-Device-ID")
        if not device_id:
            raise HTTPException(
                status_code=400,
                detail="Device ID required",
            )

        timestamp_str = request.headers.get("X-Timestamp")
        if not timestamp_str:
            raise HTTPException(
                status_code=400,
                detail="Request timestamp required",
            )

        try:
            timestamp = int(timestamp_str)
            now = int(time.time())
            if abs(now - timestamp) > 300:  # 5 minutes
                raise HTTPException(
                    status_code=400,
                    detail="Request expired",
                )
        except ValueError:
            raise HTTPException(
                status_code=400,
                detail="Invalid timestamp format",
            )

    def check_prompt_injection(self, content: str) -> bool:
        """
        Check message for prompt injection attempts.

        Args:
            content: Message content to check

        Returns:
            True if injection detected, False otherwise
        """
        lower_content = content.lower()
        for pattern in INJECTION_PATTERNS:
            if pattern in lower_content:
                logger.warning(f"Prompt injection attempt detected: {pattern}")
                return True
        return False

    async def check_message_repetition(
        self, user_id: str, content: str
    ) -> None:
        """
        Check for excessive message repetition (same message 5+ times in 1 min).

        Args:
            user_id: User ID
            content: Message content

        Raises:
            HTTPException: 429 if excessive repetition detected
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            content_hash = hashlib.md5(content.encode()).hexdigest()[:16]
            key = f"msg_repeat:{user_id}:{content_hash}"

            count = await redis.incr(key)
            await redis.expire(key, 60)  # 1 minute window

            if count >= 5:
                raise HTTPException(
                    status_code=429,
                    detail="Slow down. Too many identical messages.",
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error checking repetition: {str(e)}")

    async def check_load(self) -> None:
        """
        Check server load (active streams). Shed load if over 100.

        Raises:
            HTTPException: 503 if server overloaded
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            count = await redis.get("active_streams")
            if count and int(count) > 100:
                raise HTTPException(
                    status_code=503,
                    detail="Server busy. Try again shortly.",
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"Error checking load: {str(e)}")

    async def increment_active_streams(self) -> None:
        """Increment active stream counter."""
        redis = await self._get_redis()
        if redis:
            try:
                await redis.incr("active_streams")
                await redis.expire("active_streams", 300)
            except Exception:
                pass

    async def decrement_active_streams(self) -> None:
        """Decrement active stream counter."""
        redis = await self._get_redis()
        if redis:
            try:
                await redis.decr("active_streams")
            except Exception:
                pass


    async def check_duplicate_request(
        self, user_id: str, content: str
    ) -> bool:
        """
        Prevent duplicate requests within 10 seconds.

        Args:
            user_id: User ID
            content: Request content

        Returns:
            True if duplicate detected
        """
        redis = await self._get_redis()
        if not redis:
            return False

        try:
            import hashlib
            import time as time_mod

            content_hash = hashlib.sha256(
                f"{user_id}:{content}:{int(time_mod.time() // 10)}".encode()
            ).hexdigest()[:16]

            key = f"req_dedup:{content_hash}"
            exists = await redis.get(key)

            if exists:
                return True

            await redis.set(key, "1", ex=10)
            return False
        except Exception as e:
            logger.error(f"Dedup check error: {str(e)}")
            return False

    async def check_ip_signup_blocked(self, ip: str) -> None:
        """
        Check if IP is blocked from creating new accounts.

        Args:
            ip: Client IP

        Raises:
            HTTPException: 403 if blocked
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            blocked = await redis.get(f"ip_signup_blocked:{ip}")
            if blocked:
                raise HTTPException(
                    status_code=403,
                    detail="Maximum accounts reached for this network.",
                )
        except HTTPException:
            raise
        except Exception as e:
            logger.error(f"IP signup check error: {str(e)}")

    async def track_account_creation(self, ip: str, user_id: str) -> None:
        """
        Track new account creation per IP. Block at 3, alert at 5.

        Args:
            ip: Client IP
            user_id: New user ID
        """
        redis = await self._get_redis()
        if not redis:
            return

        try:
            key = f"accounts_per_ip:{ip}"
            count = await redis.incr(key)

            # Store user_id in list
            list_key = f"ip_users:{ip}"
            await redis.lpush(list_key, user_id)

            if count >= 5:
                await redis.set(f"ip_signup_blocked:{ip}", "1")
                from app.utils.helpers import send_admin_alert
                user_ids = await redis.lrange(list_key, 0, -1)
                await send_admin_alert(
                    f"IP flagged: {ip} - {count} accounts",
                    f"User IDs: {user_ids}",
                )
                await redis.set(f"ip_flagged:{ip}", "1")
                logger.warning(f"IP flagged for multiple accounts: {ip}")

            elif count >= 3:
                await redis.set(f"ip_signup_blocked:{ip}", "1")
                logger.warning(f"IP blocked for signups: {ip} ({count} accounts)")

        except Exception as e:
            logger.error(f"Account tracking error: {str(e)}")


security_middleware = SecurityMiddleware()
