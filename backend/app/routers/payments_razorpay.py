"""Razorpay payments router - handles subscriptions for value bucket (India)."""

import hashlib
import hmac
import logging

import razorpay
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.config import get_settings
from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.services.rate_limiter import rate_limiter

logger = logging.getLogger(__name__)

router = APIRouter()

settings = get_settings()
razorpay_client = razorpay.Client(
    auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET)
)

RAZORPAY_AMOUNTS = {
    "basic": 9900,   # ₹99 in paise
    "pro": 29900,    # ₹299 in paise
}


class RazorpayCreateRequest(BaseModel):
    """Request model for creating Razorpay subscription."""

    plan: str = Field(..., description="Plan: basic or pro")


class RazorpayVerifyRequest(BaseModel):
    """Request model for verifying Razorpay payment."""

    payment_id: str = Field(..., description="Razorpay payment ID")
    subscription_id: str = Field(..., description="Razorpay subscription ID")
    signature: str = Field(..., description="Razorpay signature")


@router.post("/create-subscription", dependencies=[Depends(rate_limiter.get_limiter_dependency("payment"))])
async def create_subscription(
    body: RazorpayCreateRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Create a Razorpay subscription for value bucket users (India).
    """
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()

        # Get subscription
        sub_result = (
            supabase.table("subscriptions")
            .select("*")
            .eq("user_id", user_id)
            .execute()
        )
        if not sub_result.data:
            raise HTTPException(status_code=404, detail="No subscription found")

        subscription = sub_result.data[0]
        country_bucket = subscription.get("country_bucket", "premium")

        if country_bucket != "value":
            raise HTTPException(
                status_code=400,
                detail="Use Stripe for your region",
            )

        # Get or create Razorpay customer
        razorpay_customer_id = subscription.get("razorpay_customer_id")
        if not razorpay_customer_id:
            user_result = (
                supabase.table("users")
                .select("email, name")
                .eq("id", user_id)
                .execute()
            )
            user_data = user_result.data[0] if user_result.data else {}

            customer = razorpay_client.customer.create({
                "name": user_data.get("name", ""),
                "email": user_data.get("email", ""),
            })
            razorpay_customer_id = customer["id"]

            supabase.table("subscriptions").update({
                "razorpay_customer_id": razorpay_customer_id,
            }).eq("user_id", user_id).execute()

        # Get plan ID from settings
        plan_id_attr = f"RAZORPAY_{body.plan.upper()}_PLAN_ID"
        plan_id = getattr(settings, plan_id_attr, "")
        if not plan_id:
            raise HTTPException(status_code=400, detail=f"No Razorpay plan configured for {body.plan}")

        # Create subscription
        rz_subscription = razorpay_client.subscription.create({
            "plan_id": plan_id,
            "customer_id": razorpay_customer_id,
            "quantity": 1,
            "total_count": 120,
            "notes": {"user_id": user_id},
        })

        amount = RAZORPAY_AMOUNTS.get(body.plan, 9900)

        logger.info(f"Razorpay subscription created for user {user_id}, plan: {body.plan}")
        return {
            "subscription_id": rz_subscription["id"],
            "razorpay_key_id": settings.RAZORPAY_KEY_ID,
            "amount": amount,
            "currency": "INR",
            "name": "Mio",
            "description": f"Mio {body.plan.title()} Plan",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Razorpay create error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create subscription")


@router.post("/verify-payment", dependencies=[Depends(rate_limiter.get_limiter_dependency("payment"))])
async def verify_payment(
    body: RazorpayVerifyRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Verify Razorpay payment signature and activate subscription.
    """
    try:
        user_id = current_user["id"]

        # Verify signature
        expected_signature = hmac.new(
            settings.RAZORPAY_KEY_SECRET.encode(),
            f"{body.payment_id}|{body.subscription_id}".encode(),
            hashlib.sha256,
        ).hexdigest()

        if expected_signature != body.signature:
            raise HTTPException(
                status_code=400,
                detail="Payment verification failed",
            )

        # Get subscription details from Razorpay
        rz_sub = razorpay_client.subscription.fetch(body.subscription_id)
        plan_id = rz_sub.get("plan_id", "")

        # Determine plan from plan_id
        plan = "basic"
        pro_plan_id = getattr(settings, "RAZORPAY_PRO_PLAN_ID", "")
        if plan_id == pro_plan_id:
            plan = "pro"

        # Update subscription in DB
        supabase = get_supabase_client()
        supabase.table("subscriptions").update({
            "plan": plan,
            "status": "active",
            "razorpay_subscription_id": body.subscription_id,
        }).eq("user_id", user_id).execute()

        logger.info(f"Razorpay payment verified for user {user_id}, plan: {plan}")
        return {
            "success": True,
            "plan": plan,
            "message": "Subscription activated",
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Razorpay verify error: {str(e)}")
        raise HTTPException(status_code=500, detail="Payment verification failed")


@router.get("/status", dependencies=[Depends(rate_limiter.get_limiter_dependency("general"))])
async def get_status(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Get subscription status, fetching live data from Razorpay if available."""
    try:
        supabase = get_supabase_client()
        result = (
            supabase.table("subscriptions")
            .select("*")
            .eq("user_id", current_user["id"])
            .execute()
        )

        if not result.data:
            return {"plan": "free", "status": "active"}

        subscription = result.data[0]
        rz_sub_id = subscription.get("razorpay_subscription_id")

        if rz_sub_id:
            try:
                rz_sub = razorpay_client.subscription.fetch(rz_sub_id)
                subscription["razorpay_status"] = rz_sub.get("status")
            except Exception as e:
                logger.error(f"Failed to fetch Razorpay status: {str(e)}")

        return subscription

    except Exception as e:
        logger.error(f"Error getting status: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get status")
