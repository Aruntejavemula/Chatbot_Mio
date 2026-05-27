"""Stripe payments router - handles checkout, portal, and subscription status."""

import logging

import stripe
from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel, Field

from app.config import get_settings
from app.middleware.auth_middleware import get_current_user, get_supabase_client
from app.services.rate_limiter import rate_limiter

logger = logging.getLogger(__name__)

router = APIRouter()

settings = get_settings()
stripe.api_key = settings.STRIPE_SECRET_KEY

FRONTEND_URL = settings.ALLOWED_ORIGINS.split(",")[0]


class StripeCheckoutRequest(BaseModel):
    """Request model for creating Stripe checkout session."""

    plan: str = Field(..., description="Plan: basic or pro")
    period: str = Field(default="monthly", description="Period: monthly or annual")


@router.post("/create-checkout", dependencies=[Depends(rate_limiter.get_limiter_dependency("payment"))])
async def create_checkout(
    body: StripeCheckoutRequest,
    current_user: dict = Depends(get_current_user),
) -> dict:
    """
    Create a Stripe checkout session for subscription.
    Only for premium and middle bucket users.
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

        if country_bucket == "value":
            raise HTTPException(
                status_code=400,
                detail="Use Razorpay for your region",
            )

        # Get or create Stripe customer
        stripe_customer_id = subscription.get("stripe_customer_id")
        if not stripe_customer_id:
            # Get user info
            user_result = (
                supabase.table("users")
                .select("email, name")
                .eq("id", user_id)
                .execute()
            )
            user_data = user_result.data[0] if user_result.data else {}

            customer = stripe.Customer.create(
                email=user_data.get("email", ""),
                name=user_data.get("name", ""),
                metadata={"user_id": user_id},
            )
            stripe_customer_id = customer.id

            # Save customer ID
            supabase.table("subscriptions").update({
                "stripe_customer_id": stripe_customer_id,
            }).eq("user_id", user_id).execute()

        # Get correct price ID
        price_id = _get_price_id(body.plan, body.period, country_bucket)
        if not price_id:
            raise HTTPException(status_code=400, detail="Invalid plan or period")

        # Create checkout session
        session = stripe.checkout.Session.create(
            mode="subscription",
            customer=stripe_customer_id,
            line_items=[{"price": price_id, "quantity": 1}],
            success_url=f"{FRONTEND_URL}/subscription?success=true",
            cancel_url=f"{FRONTEND_URL}/subscription?cancelled=true",
            metadata={"user_id": user_id, "plan": body.plan},
            allow_promotion_codes=True,
        )

        logger.info(f"Stripe checkout created for user {user_id}, plan: {body.plan}")
        return {
            "checkout_url": session.url,
            "session_id": session.id,
        }

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Stripe checkout error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create checkout")


@router.post("/create-portal", dependencies=[Depends(rate_limiter.get_limiter_dependency("payment"))])
async def create_portal(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Create a Stripe billing portal session for managing subscription."""
    try:
        user_id = current_user["id"]
        supabase = get_supabase_client()

        sub_result = (
            supabase.table("subscriptions")
            .select("stripe_customer_id")
            .eq("user_id", user_id)
            .execute()
        )

        if not sub_result.data or not sub_result.data[0].get("stripe_customer_id"):
            raise HTTPException(
                status_code=404,
                detail="No Stripe subscription found",
            )

        stripe_customer_id = sub_result.data[0]["stripe_customer_id"]

        session = stripe.billing_portal.Session.create(
            customer=stripe_customer_id,
            return_url=f"{FRONTEND_URL}/settings/subscription",
        )

        return {"portal_url": session.url}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Stripe portal error: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to create portal")


@router.get("/status", dependencies=[Depends(rate_limiter.get_limiter_dependency("general"))])
async def get_status(
    current_user: dict = Depends(get_current_user),
) -> dict:
    """Get current subscription status."""
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

        return result.data[0]

    except Exception as e:
        logger.error(f"Error getting status: {str(e)}")
        raise HTTPException(status_code=500, detail="Failed to get status")


def _get_price_id(plan: str, period: str, country_bucket: str) -> str:
    """Get Stripe price ID based on plan, period, and bucket."""
    if country_bucket == "middle":
        if plan == "basic":
            return getattr(settings, "STRIPE_MIDDLE_BASIC_PRICE_ID", "") or settings.STRIPE_BASIC_PRICE_ID_MONTHLY
        elif plan == "pro":
            return getattr(settings, "STRIPE_MIDDLE_PRO_PRICE_ID", "") or settings.STRIPE_PRO_PRICE_ID_MONTHLY
    else:
        if plan == "basic":
            if period == "annual":
                return settings.STRIPE_BASIC_PRICE_ID_ANNUAL
            return settings.STRIPE_BASIC_PRICE_ID_MONTHLY
        elif plan == "pro":
            if period == "annual":
                return settings.STRIPE_PRO_PRICE_ID_ANNUAL
            return settings.STRIPE_PRO_PRICE_ID_MONTHLY
    return ""
