"""Device models for request/response validation."""

from datetime import datetime

from pydantic import BaseModel, Field


class DeviceCreate(BaseModel):
    """Model for registering a new device."""

    device_id: str = Field(..., description="Unique device identifier hash")
    device_name: str = Field(..., description="Human-readable device name")
    device_type: str = Field(..., description="Device type: ios/android/web/desktop")


class DeviceResponse(BaseModel):
    """Model for device API responses."""

    id: str = Field(..., description="Unique record ID")
    user_id: str = Field(..., description="Owner user ID")
    device_id: str = Field(..., description="Unique device identifier hash")
    device_name: str = Field(..., description="Human-readable device name")
    device_type: str = Field(..., description="Device type: ios/android/web/desktop")
    last_seen: datetime = Field(..., description="Last activity timestamp")
    created_at: datetime = Field(..., description="Registration timestamp")

    class Config:
        from_attributes = True
