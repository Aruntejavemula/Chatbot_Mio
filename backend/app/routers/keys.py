"""Keys router - handles API key management for AI providers."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.get("/")
async def get_keys() -> dict:
    """Get all stored API keys for the current user."""
    pass


@router.post("/")
async def store_key() -> dict:
    """Store a new API key for a provider."""
    pass


@router.delete("/{provider}")
async def delete_key(provider: str) -> dict:
    """Delete an API key for a specific provider."""
    pass


@router.post("/test")
async def test_key() -> dict:
    """Test if an API key is valid."""
    pass
