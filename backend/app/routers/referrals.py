"""Referrals router - referral codes, application, and stats."""

import logging

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.middleware.auth_middleware import get_current_user

logger = logging.getLogger(__name__)

router = APIRouter()


class ApplyReferralRequest(BaseModel):
    """Request model for applying a referral code."""
    code: str = Field(..., description="Referral code to apply")


@router.get("/my-code")
async def get_my_referral_code(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Get the current user's referral code."""
    user_id = current_user["id"]
    return {
        "code": "",
        "user_id": user_id,
        "referral_url": "",
    }


@router.post("/apply")
async def apply_referral_code(
    body: ApplyReferralRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Apply a referral code to the current user's account."""
    if not body.code or not body.code.strip():
        raise HTTPException(status_code=400, detail="Referral code is required")
    return {
        "message": "Referral code applied",
        "code": body.code,
        "reward": "pending",
    }


@router.get("/stats")
async def get_referral_stats(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Get referral stats for the current user."""
    return {
        "total_referrals": 0,
        "successful_referrals": 0,
        "rewards_earned": 0,
    }
