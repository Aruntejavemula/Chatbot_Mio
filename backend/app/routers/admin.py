"""Admin router - dashboard stats, user management, and revenue."""

import logging

from fastapi import APIRouter, Depends, HTTPException

from app.config import get_settings
from app.middleware.auth_middleware import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


async def require_admin(current_user: dict = Depends(get_current_user)) -> dict:
    """Dependency that ensures the current user is an admin."""
    settings = get_settings()
    if current_user.get("email") != settings.ADMIN_EMAIL:
        raise HTTPException(status_code=403, detail="Admin access required")
    return current_user


@router.get("/stats")
async def get_stats(admin: dict = Depends(require_admin)) -> dict:
    """Get platform-wide statistics."""
    return {
        "total_users": 0,
        "active_users_today": 0,
        "total_chats": 0,
        "total_messages": 0,
        "total_tokens_used": 0,
    }


@router.get("/users")
async def get_users(admin: dict = Depends(require_admin)) -> list[dict]:
    """Get list of all users."""
    return []


@router.get("/users/{user_id}")
async def get_user(user_id: str, admin: dict = Depends(require_admin)) -> dict:
    """Get details for a specific user."""
    return {
        "id": user_id,
        "email": "",
        "plan": "free",
        "created_at": "",
        "suspended": False,
    }


@router.post("/users/{user_id}/suspend")
async def suspend_user(user_id: str, admin: dict = Depends(require_admin)) -> dict:
    """Suspend a user account."""
    return {"message": f"User {user_id} suspended", "suspended": True}


@router.post("/users/{user_id}/unsuspend")
async def unsuspend_user(user_id: str, admin: dict = Depends(require_admin)) -> dict:
    """Unsuspend a user account."""
    return {"message": f"User {user_id} unsuspended", "suspended": False}


@router.get("/revenue")
async def get_revenue(admin: dict = Depends(require_admin)) -> dict:
    """Get revenue statistics."""
    return {
        "total_revenue": 0.0,
        "monthly_revenue": 0.0,
        "subscribers": {"basic": 0, "pro": 0},
    }
