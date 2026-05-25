"""Authentication middleware for request authorization."""

import logging
from typing import Any

from fastapi import Header, HTTPException

logger = logging.getLogger(__name__)


async def get_current_user(
    authorization: str = Header(...),
) -> dict[str, Any]:
    """Validate the Authorization header and return current user.

    Extracts the Bearer token from the Authorization header and
    performs placeholder validation. In production, this would
    verify a JWT token against a secret key.

    Args:
        authorization: The Authorization header value.

    Returns:
        A dict containing user_id extracted from the token.

    Raises:
        HTTPException: If the authorization header is missing or invalid.
    """
    if not authorization.startswith("Bearer "):
        logger.warning("Invalid authorization header format")
        raise HTTPException(
            status_code=401,
            detail="Invalid authorization header. Expected 'Bearer <token>'.",
        )

    token = authorization[len("Bearer "):]

    if not token or len(token) < 10:
        logger.warning("Invalid or empty token provided")
        raise HTTPException(
            status_code=401,
            detail="Invalid or expired token.",
        )

    # Placeholder: In production, decode and verify JWT here
    logger.debug("Token validated for user")
    return {"user_id": token[:8]}
