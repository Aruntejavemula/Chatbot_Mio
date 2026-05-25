"""API Keys router - handles BYOK key management with encryption."""

import logging
from typing import Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field
from supabase import Client

from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.services.encryption_service import EncryptionService

logger = logging.getLogger(__name__)

router = APIRouter()

encryption_service = EncryptionService()


class KeySaveRequest(BaseModel):
    """Request model for saving an API key."""

    provider: str = Field(..., description="AI provider name")
    raw_key: str = Field(..., description="Raw API key (will be encrypted)")
    custom_base_url: Optional[str] = Field(None, description="Custom base URL for provider")
    custom_model: Optional[str] = Field(None, description="Custom model identifier")


class KeyTestRequest(BaseModel):
    """Request model for testing an API key."""

    provider: str = Field(..., description="AI provider name")
    raw_key: str = Field(..., description="Raw API key to test")
    model: Optional[str] = Field(None, description="Model to test with")


class KeyResponse(BaseModel):
    """Response model for saved keys (never includes the actual key)."""

    provider: str = Field(..., description="Provider name")
    created_at: str = Field(..., description="When the key was saved")
    status: str = Field(default="connected", description="Key status")


async def get_decrypted_key(
    user_id: str,
    provider: str,
    supabase: Client,
) -> str:
    """
    Get and decrypt a user's API key for a provider.

    Args:
        user_id: User ID
        provider: Provider name
        supabase: Supabase client instance

    Returns:
        Decrypted API key string

    Raises:
        HTTPException: 404 if no key found, 500 if decryption fails
    """
    try:
        result = (
            supabase.table("api_keys")
            .select("encrypted_key, iv")
            .eq("user_id", user_id)
            .eq("provider", provider.lower())
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail=f"No API key found for {provider}. Add one in settings.",
            )

        key_data = result.data[0]
        decrypted = encryption_service.decrypt(
            key_data["encrypted_key"], key_data["iv"]
        )
        return decrypted

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Failed to retrieve key for {provider}: {type(e).__name__}")
        raise HTTPException(status_code=500, detail="Failed to retrieve API key")


@router.get("/")
async def get_keys(current_user: dict = Depends(get_current_user)) -> list[dict]:
    """
    Get list of connected providers for current user.
    Never returns the actual encrypted key or IV.
    """
    try:
        supabase = get_supabase_client()
        result = (
            supabase.table("api_keys")
            .select("provider, created_at")
            .eq("user_id", current_user["id"])
            .execute()
        )

        keys = []
        for row in result.data or []:
            keys.append({
                "provider": row["provider"],
                "created_at": row["created_at"],
                "status": "connected",
            })

        return keys

    except Exception as e:
        logger.error(f"Error fetching keys: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to fetch keys")


@router.post("/")
async def save_key(
    body: KeySaveRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Encrypt and save an API key for a provider.
    Key is encrypted server-side with AES-256-GCM.
    Raw key is never stored or logged.
    """
    raw_key = body.raw_key
    provider = body.provider.lower()

    try:
        # Validate key format
        if not encryption_service.validate_key_format(provider, raw_key):
            raise HTTPException(
                status_code=400,
                detail=f"Invalid key format for {provider}",
            )

        # Encrypt the key
        encrypted_data = encryption_service.encrypt(raw_key)

        # Save to database (upsert)
        supabase = get_supabase_client()
        supabase.table("api_keys").upsert(
            {
                "user_id": current_user["id"],
                "provider": provider,
                "encrypted_key": encrypted_data["encrypted"],
                "iv": encrypted_data["iv"],
            },
            on_conflict="user_id,provider",
        ).execute()

        logger.info(f"Key saved for provider {provider}, user {current_user['id']}")

        return {
            "provider": provider,
            "status": "saved",
            "message": "Key saved securely",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error saving key: {type(e).__name__}")
        raise HTTPException(status_code=500, detail="Failed to save key")
    finally:
        # Clear raw key from memory
        del raw_key


@router.delete("/{provider}")
async def delete_key(
    provider: str,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Delete an API key for a provider."""
    try:
        supabase = get_supabase_client()
        result = (
            supabase.table("api_keys")
            .delete()
            .eq("user_id", current_user["id"])
            .eq("provider", provider.lower())
            .execute()
        )

        if not result.data:
            raise HTTPException(
                status_code=404,
                detail=f"No key found for {provider}",
            )

        logger.info(f"Key deleted for provider {provider}, user {current_user['id']}")
        return {"message": f"Key for {provider} deleted"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting key: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to delete key")


@router.post("/test")
async def test_key(
    body: KeyTestRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Test if an API key is valid by making a minimal request.
    Does NOT save the key. Never logs the key.
    """
    raw_key = body.raw_key
    provider = body.provider.lower()

    try:
        # Validate format first
        if not encryption_service.validate_key_format(provider, raw_key):
            return {
                "valid": False,
                "message": f"Invalid key format for {provider}",
            }

        # Test the key
        is_valid = await encryption_service.test_key(
            provider=provider,
            model=body.model or "",
            api_key=raw_key,
        )

        if is_valid:
            return {"valid": True, "message": "Key is valid"}
        else:
            return {"valid": False, "message": "Key is invalid or expired"}

    except Exception as e:
        logger.error(f"Error testing key: {type(e).__name__}")
        return {"valid": False, "message": "Failed to test key"}
    finally:
        # Clear raw key from memory
        del raw_key
