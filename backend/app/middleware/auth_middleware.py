"""Authentication middleware for JWT token verification."""

import logging
from typing import Optional

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from supabase import Client, create_client

from app.config import get_settings

logger = logging.getLogger(__name__)

security = HTTPBearer(auto_error=False)


def get_supabase_client() -> Client:
    """Get Supabase client with service role key."""
    settings = get_settings()
    return create_client(settings.SUPABASE_URL, settings.SUPABASE_SERVICE_KEY)


async def verify_token(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> dict:
    """
    Extract and verify JWT from Authorization header.
    Returns user payload if valid.
    Raises 401 if invalid or missing.
    """
    if not credentials:
        logger.warning("No token provided in request")
        raise HTTPException(status_code=401, detail="No token provided")

    token = credentials.credentials

    try:
        supabase = get_supabase_client()
        user_response = supabase.auth.get_user(token)

        if not user_response or not user_response.user:
            logger.warning("Token verification failed: no user returned")
            raise HTTPException(status_code=401, detail="Invalid token")

        user = user_response.user
        logger.info(f"Token verified for user: {user.id}")

        return {
            "id": user.id,
            "email": user.email,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Token verification error: {str(e)}")
        raise HTTPException(status_code=401, detail="Invalid or expired token")


async def get_current_user(
    user: dict = Depends(verify_token),
) -> dict:
    """
    Get current authenticated user from request.
    Use as a FastAPI dependency in protected endpoints.
    """
    return user
