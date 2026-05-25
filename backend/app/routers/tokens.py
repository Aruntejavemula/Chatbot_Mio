"""Tokens router - handles token usage tracking and loading words."""

import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.services.token_service import TokenService

logger = logging.getLogger(__name__)

router = APIRouter()

token_service = TokenService()


class TrackUsageRequest(BaseModel):
    """Request model for tracking token usage."""

    input_tokens: int = Field(..., description="Number of input tokens consumed")
    output_tokens: int = Field(..., description="Number of output tokens consumed")
    model: str = Field(..., description="Model that consumed the tokens")


async def _get_redis_client():
    """Get Upstash Redis client."""
    try:
        from upstash_redis.asyncio import Redis
        from app.config import get_settings
        settings = get_settings()
        return Redis(
            url=settings.UPSTASH_REDIS_URL,
            token=settings.UPSTASH_REDIS_TOKEN,
        )
    except Exception as e:
        logger.error(f"Failed to create Redis client: {str(e)}")
        return None


@router.get("/usage")
async def get_usage(current_user: dict = Depends(get_current_user)) -> dict:
    """
    Get token usage summary for current user.
    Returns daily and monthly usage with limits.
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()
        redis = await _get_redis_client()

        # Get subscription for plan and bucket
        sub_result = (
            supabase.table("subscriptions")
            .select("plan, country_bucket")
            .eq("user_id", user_id)
            .execute()
        )

        plan = "free"
        country_bucket = "premium"
        if sub_result.data:
            plan = sub_result.data[0].get("plan", "free")
            country_bucket = sub_result.data[0].get("country_bucket", "premium")

        summary = await token_service.get_usage_summary(
            user_id=user_id,
            plan=plan,
            country_bucket=country_bucket,
            redis_client=redis,
            supabase_client=supabase,
        )

        return summary

    except Exception as e:
        logger.error(f"Error getting usage: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get usage data")


@router.get("/loading-word")
async def get_loading_word(current_user: dict = Depends(get_current_user)) -> dict:
    """
    Get next loading word in sequence.
    Updates the index in settings table.
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()

        # Get current index from settings
        settings_result = (
            supabase.table("settings")
            .select("loading_word_index")
            .eq("user_id", user_id)
            .execute()
        )

        current_index = 0
        if settings_result.data:
            current_index = settings_result.data[0].get("loading_word_index", 0)

        # Get word and next index
        word, next_index = token_service.get_next_loading_word(current_index)

        # Update index in settings
        supabase.table("settings").update({
            "loading_word_index": next_index,
        }).eq("user_id", user_id).execute()

        return {
            "word": word,
            "index": next_index,
        }

    except Exception as e:
        logger.error(f"Error getting loading word: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get loading word")


@router.post("/track")
async def track_usage(
    body: TrackUsageRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Track token usage after AI response.
    Internal endpoint called by chat router.
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()
        redis = await _get_redis_client()

        await token_service.track_usage(
            user_id=user_id,
            input_tokens=body.input_tokens,
            output_tokens=body.output_tokens,
            model=body.model,
            redis_client=redis,
            supabase_client=supabase,
        )

        return {"message": "Usage tracked successfully"}

    except Exception as e:
        logger.error(f"Error tracking usage: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to track usage")
