"""Settings router - handles user preferences and configuration."""

import logging
from typing import Any, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.utils.constants import SUPPORTED_PROVIDERS
from app.services.rate_limiter import rate_limiter

logger = logging.getLogger(__name__)

router = APIRouter()


class SettingsUpdateRequest(BaseModel):
    """Request model for updating settings. All fields optional."""

    theme: Optional[str] = Field(None, description="Theme: light/dark/system")
    zero_fluff_on: Optional[bool] = Field(None, description="Enable zero-fluff mode")
    default_model: Optional[str] = Field(None, description="Default AI model")
    default_provider: Optional[str] = Field(None, description="Default AI provider")
    loading_word_index: Optional[int] = Field(None, description="Loading word index")
    preferences: Optional[dict[str, Any]] = Field(None, description="Additional preferences")


@router.get("/", dependencies=[Depends(rate_limiter.get_limiter_dependency("general"))])
async def get_settings(current_user: dict = Depends(get_current_user)) -> dict:
    """
    Get user settings. Creates defaults if not exists.
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()

        result = (
            supabase.table("settings")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )

        if result.data:
            settings = result.data[0]
            return {
                "theme": settings.get("theme", "system"),
                "zero_fluff_on": settings.get("zero_fluff_on", True),
                "default_model": settings.get("default_model", ""),
                "default_provider": settings.get("default_provider", ""),
                "loading_word_index": settings.get("loading_word_index", 0),
                "preferences": settings.get("preferences", {}),
            }

        # Create defaults if not exists
        new_settings = (
            supabase.table("settings")
            .insert({"user_id": user_id})
            .execute()
        )

        if new_settings.data:
            row = new_settings.data[0]
            return {
                "theme": row.get("theme", "system"),
                "zero_fluff_on": row.get("zero_fluff_on", True),
                "default_model": row.get("default_model", ""),
                "default_provider": row.get("default_provider", ""),
                "loading_word_index": row.get("loading_word_index", 0),
                "preferences": row.get("preferences", {}),
            }

        return {
            "theme": "system",
            "zero_fluff_on": True,
            "default_model": "",
            "default_provider": "",
            "loading_word_index": 0,
            "preferences": {},
        }

    except Exception as e:
        logger.error(f"Error getting settings: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get settings")


@router.patch("/", dependencies=[Depends(rate_limiter.get_limiter_dependency("general"))])
async def update_settings(
    body: SettingsUpdateRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Update user settings. Only updates provided fields.
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()

        # Build update dict from non-None fields
        update_data = {}
        if body.theme is not None:
            if body.theme not in ("light", "dark", "system"):
                raise HTTPException(status_code=400, detail="Invalid theme value")
            update_data["theme"] = body.theme
        if body.zero_fluff_on is not None:
            update_data["zero_fluff_on"] = body.zero_fluff_on
        if body.default_model is not None:
            update_data["default_model"] = body.default_model
        if body.default_provider is not None:
            update_data["default_provider"] = body.default_provider
        if body.loading_word_index is not None:
            update_data["loading_word_index"] = body.loading_word_index
        if body.preferences is not None:
            update_data["preferences"] = body.preferences

        if not update_data:
            raise HTTPException(status_code=400, detail="No fields to update")

        # Upsert settings
        result = (
            supabase.table("settings")
            .upsert(
                {"user_id": user_id, **update_data},
                on_conflict="user_id",
            )
            .execute()
        )

        if result.data:
            row = result.data[0]
            return {
                "theme": row.get("theme", "system"),
                "zero_fluff_on": row.get("zero_fluff_on", True),
                "default_model": row.get("default_model", ""),
                "default_provider": row.get("default_provider", ""),
                "loading_word_index": row.get("loading_word_index", 0),
                "preferences": row.get("preferences", {}),
            }

        return update_data

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating settings: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to update settings")


@router.get("/providers", dependencies=[Depends(rate_limiter.get_limiter_dependency("providers"))])
async def get_providers() -> list[dict]:
    """
    Get list of supported AI providers and their models.
    No authentication required.
    """
    return SUPPORTED_PROVIDERS
