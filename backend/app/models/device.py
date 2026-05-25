"""Device models - Pydantic schemas for device registration data."""

from pydantic import BaseModel
from typing import Optional


class DeviceRegister(BaseModel):
    """Schema for registering a new device."""

    device_id: str
    device_name: str
    platform: str
    push_token: Optional[str] = None


class DeviceResponse(BaseModel):
    """Schema for device response data."""

    id: str
    device_id: str
    device_name: str
    platform: str
    last_active: str
    created_at: str
