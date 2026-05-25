"""Devices router - handles device registration and management."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.post("/register")
async def register_device() -> dict:
    """Register a new device for the current user."""
    pass


@router.get("/")
async def get_devices() -> dict:
    """Get all registered devices for the current user."""
    pass


@router.delete("/{device_id}")
async def delete_device(device_id: str) -> dict:
    """Remove a registered device."""
    pass
