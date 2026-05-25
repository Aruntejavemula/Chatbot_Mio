"""Settings router - handles user preferences and app settings."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.get("/preferences")
async def get_preferences() -> dict:
    """Get user preferences."""
    pass


@router.patch("/preferences")
async def update_preferences() -> dict:
    """Update user preferences."""
    pass
