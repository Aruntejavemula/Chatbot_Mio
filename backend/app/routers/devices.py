"""Devices router - handles device registration and management."""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user, get_supabase_client

logger = logging.getLogger(__name__)

router = APIRouter()

DEVICE_LIMITS = {
    "free": 1,
    "basic": 2,
    "pro": 5,
}


class DeviceRegisterRequest(BaseModel):
    """Request model for device registration."""

    device_id: str = Field(..., description="SHA-256 device fingerprint")
    device_name: str = Field(..., description="Human-readable device name")
    device_type: str = Field(..., description="Device type: ios/android/web/desktop")


class DeviceUpdateSeenRequest(BaseModel):
    """Request model for updating device last_seen."""

    device_id: str = Field(..., description="Device ID to update")


@router.post("/register")
async def register_device(
    body: DeviceRegisterRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Register a new device or update last_seen if already registered.
    Checks device limit based on user's plan.
    Returns 409 if limit reached with existing device list.
    """
    user_id = current_user["id"]

    try:
        supabase = get_supabase_client()

        # Check if device already registered
        existing = (
            supabase.table("devices")
            .select("*")
            .eq("user_id", user_id)
            .eq("device_id", body.device_id)
            .execute()
        )

        if existing.data:
            # Update last_seen
            supabase.table("devices").update({
                "last_seen": "now()",
                "device_name": body.device_name,
            }).eq("user_id", user_id).eq("device_id", body.device_id).execute()

            logger.info(f"Device updated for user {user_id}: {body.device_id[:8]}...")
            return {"message": "Device updated", "status": "existing"}

        # Count existing devices
        all_devices = (
            supabase.table("devices")
            .select("id, device_name, device_type, last_seen")
            .eq("user_id", user_id)
            .execute()
        )
        current_count = len(all_devices.data) if all_devices.data else 0

        # Get user plan
        sub_result = (
            supabase.table("subscriptions")
            .select("plan")
            .eq("user_id", user_id)
            .execute()
        )
        plan = sub_result.data[0]["plan"] if sub_result.data else "free"

        # Check device limit
        limit = DEVICE_LIMITS.get(plan, 1)
        if current_count >= limit:
            raise HTTPException(
                status_code=409,
                detail={
                    "message": "Device limit reached",
                    "limit": limit,
                    "current": current_count,
                    "devices": all_devices.data or [],
                },
            )

        # Register new device
        supabase.table("devices").insert({
            "user_id": user_id,
            "device_id": body.device_id,
            "device_name": body.device_name,
            "device_type": body.device_type,
        }).execute()

        logger.info(f"New device registered for user {user_id}: {body.device_type}")
        return {"message": "Device registered", "status": "new"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error registering device: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to register device")


@router.get("/")
async def get_devices(
    current_user: dict = Depends(get_current_user),
    device_id: Optional[str] = None,
) -> list[dict]:
    """
    Get all devices for current user.
    Marks current device if device_id query param provided.
    """
    try:
        supabase = get_supabase_client()
        result = (
            supabase.table("devices")
            .select("*")
            .eq("user_id", current_user["id"])
            .order("last_seen", desc=True)
            .execute()
        )

        devices = result.data or []

        # Mark current device
        for device in devices:
            device["is_current"] = device.get("device_id") == device_id

        return devices

    except Exception as e:
        logger.error(f"Error fetching devices: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch devices")


@router.delete("/{device_id}")
async def remove_device(
    device_id: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Remove a device from user's registered devices."""
    try:
        supabase = get_supabase_client()

        # Verify device belongs to user
        result = (
            supabase.table("devices")
            .select("id")
            .eq("user_id", current_user["id"])
            .eq("device_id", device_id)
            .execute()
        )

        if not result.data:
            raise HTTPException(status_code=404, detail="Device not found")

        supabase.table("devices").delete().eq(
            "user_id", current_user["id"]
        ).eq("device_id", device_id).execute()

        logger.info(f"Device removed for user {current_user['id']}: {device_id[:8]}...")
        return {"message": "Device removed"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error removing device: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to remove device")


@router.post("/update-seen")
async def update_device_seen(
    body: DeviceUpdateSeenRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Update last_seen timestamp for a device."""
    try:
        supabase = get_supabase_client()

        supabase.table("devices").update({
            "last_seen": "now()",
        }).eq("user_id", current_user["id"]).eq(
            "device_id", body.device_id
        ).execute()

        return {"message": "Device seen updated"}

    except Exception as e:
        logger.error(f"Error updating device seen: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update device")
