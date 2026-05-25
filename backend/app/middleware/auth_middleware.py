"""Authentication middleware - JWT verification and user extraction."""

from fastapi import Depends, HTTPException, Header
from typing import Optional


async def verify_token(authorization: Optional[str] = Header(None)) -> dict:
    """Verify JWT token from Authorization header.

    Args:
        authorization: Bearer token from request header.

    Returns:
        Decoded token payload.

    Raises:
        HTTPException: If token is missing or invalid.
    """
    if not authorization:
        raise HTTPException(status_code=401, detail="Authorization header missing")

    if not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Invalid authorization format")

    token = authorization.replace("Bearer ", "")
    # TODO: Implement actual JWT verification with Supabase
    return {"token": token}


async def get_current_user(token_data: dict = Depends(verify_token)) -> dict:
    """Get the current authenticated user from the token.

    Args:
        token_data: Decoded token payload from verify_token.

    Returns:
        User data dictionary.

    Raises:
        HTTPException: If user is not found.
    """
    # TODO: Implement user lookup from Supabase
    return {"id": "", "email": "", "plan": "free"}
