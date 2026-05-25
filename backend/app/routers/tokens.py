"""Tokens router - handles token usage tracking and limits."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.get("/usage")
async def get_usage() -> dict:
    """Get current token usage for the user."""
    pass


@router.get("/limits")
async def get_limits() -> dict:
    """Get token limits based on user subscription plan."""
    pass
