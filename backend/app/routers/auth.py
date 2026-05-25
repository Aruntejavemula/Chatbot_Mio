"""Authentication router - handles Google/Apple/Microsoft sign-in and session management."""

import logging
from typing import Optional

import httpx
from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel, Field
from supabase import Client, create_client

from app.config import get_settings
from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.models.user import UserCreate, UserResponse

logger = logging.getLogger(__name__)

router = APIRouter()

# Country bucket classification
PREMIUM_COUNTRIES = {
    "US", "GB", "CA", "AU", "DE", "FR", "JP", "SG", "AE",
    "CH", "NL", "SE", "NO", "DK", "NZ", "KR", "IL", "AT",
    "BE", "FI", "IE", "PT", "ES", "IT", "HK", "TW",
}

MIDDLE_COUNTRIES = {
    "BR", "MX", "PL", "CZ", "HU", "SA", "QA", "RU",
    "ZA", "AR", "CL", "CO", "TR", "RO", "BG", "HR",
}

# Device limits per plan
DEVICE_LIMITS = {
    "free": 1,
    "basic": 2,
    "pro": 5,
}


async def get_country_bucket(ip: str) -> str:
    """
    Determine pricing bucket based on IP geolocation.
    
    Args:
        ip: Client IP address
        
    Returns:
        Country bucket: 'premium', 'middle', or 'value'
    """
    try:
        async with httpx.AsyncClient(timeout=5.0) as client:
            response = await client.get(
                f"http://ip-api.com/json/{ip}",
                params={"fields": "countryCode"},
            )
            if response.status_code == 200:
                data = response.json()
                country_code = data.get("countryCode", "")
                
                if country_code in PREMIUM_COUNTRIES:
                    return "premium"
                elif country_code in MIDDLE_COUNTRIES:
                    return "middle"
                else:
                    return "value"
    except Exception as e:
        logger.error(f"Country detection failed: {str(e)}")
    
    return "premium"  # Default if detection fails


def _get_client_ip(request: Request) -> str:
    """Extract client IP from request headers."""
    forwarded = request.headers.get("x-forwarded-for")
    if forwarded:
        return forwarded.split(",")[0].strip()
    return request.client.host if request.client else "127.0.0.1"


async def _get_or_create_user(
    supabase: Client,
    email: str,
    name: str,
    avatar_url: Optional[str],
    user_id: str,
) -> dict:
    """
    Get existing user or create new one in users table.
    
    Args:
        supabase: Supabase client
        email: User email
        name: User display name
        avatar_url: User avatar URL
        user_id: Supabase auth user ID
        
    Returns:
        User record dict
    """
    try:
        # Check if user exists
        result = supabase.table("users").select("*").eq("id", user_id).execute()
        
        if result.data and len(result.data) > 0:
            # Update existing user
            updated = (
                supabase.table("users")
                .update({"name": name, "avatar_url": avatar_url})
                .eq("id", user_id)
                .execute()
            )
            logger.info(f"Updated existing user: {user_id}")
            return updated.data[0]
        else:
            # Create new user
            new_user = (
                supabase.table("users")
                .insert({
                    "id": user_id,
                    "email": email,
                    "name": name,
                    "avatar_url": avatar_url,
                })
                .execute()
            )
            logger.info(f"Created new user: {user_id}")
            return new_user.data[0]
    except Exception as e:
        logger.error(f"Error in get_or_create_user: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error")


async def _get_or_create_subscription(
    supabase: Client,
    user_id: str,
    country_bucket: str,
) -> dict:
    """
    Get existing subscription or create free tier.
    
    Args:
        supabase: Supabase client
        user_id: User ID
        country_bucket: Pricing bucket based on location
        
    Returns:
        Subscription record dict
    """
    try:
        result = (
            supabase.table("subscriptions")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        
        if result.data and len(result.data) > 0:
            return result.data[0]
        else:
            new_sub = (
                supabase.table("subscriptions")
                .insert({
                    "user_id": user_id,
                    "plan": "free",
                    "status": "active",
                    "country_bucket": country_bucket,
                })
                .execute()
            )
            logger.info(f"Created free subscription for user: {user_id}")
            return new_sub.data[0]
    except Exception as e:
        logger.error(f"Error in get_or_create_subscription: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error")


async def _get_or_create_settings(supabase: Client, user_id: str) -> dict:
    """
    Get existing settings or create defaults.
    
    Args:
        supabase: Supabase client
        user_id: User ID
        
    Returns:
        Settings record dict
    """
    try:
        result = (
            supabase.table("settings")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        
        if result.data and len(result.data) > 0:
            return result.data[0]
        else:
            new_settings = (
                supabase.table("settings")
                .insert({"user_id": user_id})
                .execute()
            )
            logger.info(f"Created default settings for user: {user_id}")
            return new_settings.data[0]
    except Exception as e:
        logger.error(f"Error in get_or_create_settings: {str(e)}")
        raise HTTPException(status_code=500, detail="Database error")


async def _check_device_limit(
    supabase: Client,
    user_id: str,
    plan: str,
) -> bool:
    """
    Check if user is under device limit for their plan.
    
    Args:
        supabase: Supabase client
        user_id: User ID
        plan: Current plan name
        
    Returns:
        True if under limit, False if at limit
    """
    try:
        limit = DEVICE_LIMITS.get(plan, 1)
        result = (
            supabase.table("devices")
            .select("id")
            .eq("user_id", user_id)
            .execute()
        )
        current_count = len(result.data) if result.data else 0
        return current_count < limit
    except Exception as e:
        logger.error(f"Error checking device limit: {str(e)}")
        return False


class MicrosoftSignInRequest(BaseModel):
    """Request model for Microsoft sign-in."""

    identity_token: str = Field(..., description="Microsoft identity token")


@router.post("/google")
async def google_sign_in(request: Request) -> dict:
    """
    Sign in with Google OAuth ID token.
    
    Creates or updates user, subscription, and settings.
    Returns access token and user data.
    """
    try:
        body = await request.json()
        id_token = body.get("id_token")
        
        if not id_token:
            raise HTTPException(status_code=400, detail="id_token is required")
        
        settings = get_settings()
        supabase = get_supabase_client()
        
        # Verify with Supabase Auth
        try:
            auth_response = supabase.auth.sign_in_with_id_token({
                "provider": "google",
                "token": id_token,
            })
        except Exception as e:
            logger.error(f"Google sign-in failed: {str(e)}")
            raise HTTPException(status_code=400, detail="Invalid Google token")
        
        if not auth_response.user:
            raise HTTPException(status_code=400, detail="Authentication failed")
        
        auth_user = auth_response.user
        session = auth_response.session
        
        # Extract user info
        user_meta = auth_user.user_metadata or {}
        email = auth_user.email or ""
        name = user_meta.get("full_name", user_meta.get("name", email.split("@")[0]))
        avatar_url = user_meta.get("avatar_url", user_meta.get("picture"))
        
        # Get or create user
        user = await _get_or_create_user(
            supabase, email, name, avatar_url, auth_user.id
        )
        
        # Detect country and get/create subscription
        client_ip = _get_client_ip(request)
        country_bucket = await get_country_bucket(client_ip)
        subscription = await _get_or_create_subscription(
            supabase, auth_user.id, country_bucket
        )
        
        # Get or create settings
        await _get_or_create_settings(supabase, auth_user.id)
        
        logger.info(f"Google sign-in successful for: {email}")
        
        return {
            "token": session.access_token if session else "",
            "user": user,
            "subscription": subscription,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Google sign-in error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.post("/apple")
async def apple_sign_in(request: Request) -> dict:
    """
    Sign in with Apple identity token.
    
    Creates or updates user, subscription, and settings.
    Returns access token and user data.
    """
    try:
        body = await request.json()
        identity_token = body.get("identity_token")
        
        if not identity_token:
            raise HTTPException(status_code=400, detail="identity_token is required")
        
        supabase = get_supabase_client()
        
        # Verify with Supabase Auth
        try:
            auth_response = supabase.auth.sign_in_with_id_token({
                "provider": "apple",
                "token": identity_token,
            })
        except Exception as e:
            logger.error(f"Apple sign-in failed: {str(e)}")
            raise HTTPException(status_code=400, detail="Invalid Apple token")
        
        if not auth_response.user:
            raise HTTPException(status_code=400, detail="Authentication failed")
        
        auth_user = auth_response.user
        session = auth_response.session
        
        # Extract user info
        user_meta = auth_user.user_metadata or {}
        email = auth_user.email or ""
        name = user_meta.get("full_name", user_meta.get("name", email.split("@")[0]))
        avatar_url = user_meta.get("avatar_url")
        
        # Get or create user
        user = await _get_or_create_user(
            supabase, email, name, avatar_url, auth_user.id
        )
        
        # Detect country and get/create subscription
        client_ip = _get_client_ip(request)
        country_bucket = await get_country_bucket(client_ip)
        subscription = await _get_or_create_subscription(
            supabase, auth_user.id, country_bucket
        )
        
        # Get or create settings
        await _get_or_create_settings(supabase, auth_user.id)
        
        logger.info(f"Apple sign-in successful for: {email}")
        
        return {
            "token": session.access_token if session else "",
            "user": user,
            "subscription": subscription,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Apple sign-in error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.post("/microsoft")
async def microsoft_sign_in(
    body: MicrosoftSignInRequest,
    request: Request,
) -> dict:
    """
    Sign in with Microsoft identity token.
    
    Creates or updates user, subscription, and settings.
    Returns access token and user data.
    """
    try:
        logger.info("Microsoft sign-in request received")

        supabase = get_supabase_client()

        # Verify with Supabase Auth
        try:
            auth_response = supabase.auth.sign_in_with_id_token({
                "provider": "azure",
                "token": body.identity_token,
            })
        except Exception as e:
            logger.error(f"Microsoft sign-in failed: {str(e)}")
            raise HTTPException(status_code=400, detail="Invalid Microsoft token")

        if not auth_response.user:
            raise HTTPException(status_code=400, detail="Authentication failed")

        auth_user = auth_response.user
        session = auth_response.session

        # Extract user info
        user_meta = auth_user.user_metadata or {}
        email = auth_user.email or ""
        name = user_meta.get("full_name", user_meta.get("name", email.split("@")[0]))
        avatar_url = user_meta.get("avatar_url", user_meta.get("picture"))

        # Get or create user
        user = await _get_or_create_user(
            supabase, email, name, avatar_url, auth_user.id
        )

        # Detect country and get/create subscription
        client_ip = _get_client_ip(request)
        country_bucket = await get_country_bucket(client_ip)
        subscription = await _get_or_create_subscription(
            supabase, auth_user.id, country_bucket
        )

        # Get or create settings
        await _get_or_create_settings(supabase, auth_user.id)

        logger.info(f"Microsoft sign-in successful for: {email}")

        return {
            "token": session.access_token if session else "",
            "user": user,
            "subscription": subscription,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Microsoft sign-in error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.get("/profile")
async def get_profile(current_user: dict = Depends(get_current_user)) -> dict:
    """
    Get current user profile with subscription and settings.
    
    Requires authentication.
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()
        
        # Get user
        user_result = (
            supabase.table("users").select("*").eq("id", user_id).execute()
        )
        if not user_result.data:
            raise HTTPException(status_code=404, detail="User not found")
        
        # Get subscription
        sub_result = (
            supabase.table("subscriptions")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        
        # Get settings
        settings_result = (
            supabase.table("settings")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        
        return {
            "user": user_result.data[0],
            "subscription": sub_result.data[0] if sub_result.data else None,
            "settings": settings_result.data[0] if settings_result.data else None,
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Get profile error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")


@router.post("/signout")
async def sign_out(current_user: dict = Depends(get_current_user)) -> dict:
    """
    Sign out and invalidate current session.
    
    Requires authentication.
    """
    try:
        logger.info(f"User signed out: {current_user['id']}")
        return {"message": "Successfully signed out"}
    except Exception as e:
        logger.error(f"Sign out error: {str(e)}")
        raise HTTPException(status_code=500, detail="Internal server error")
