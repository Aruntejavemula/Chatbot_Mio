"""Webhooks router - handles Stripe and Razorpay webhook events."""

import hashlib
import hmac
import logging

import stripe
from fastapi import APIRouter, HTTPException, Request

from app.config import get_settings
from app.middleware.auth_middleware import get_supabase_client

logger = logging.getLogger(__name__)

router = APIRouter()

settings = get_settings()
stripe.api_key = settings.STRIPE_SECRET_KEY


@router.post("/stripe")
async def stripe_webhook(request: Request) -> dict:
    """
    Handle Stripe webhook events.
    Verifies signature, processes subscription lifecycle events.
    No auth required - Stripe calls this directly.
    """
    try:
        payload = await request.body()
        signature = request.headers.get("Stripe-Signature", "")

        try:
            event = stripe.Webhook.construct_event(
                payload, signature, settings.STRIPE_WEBHOOK_SECRET
            )
        except stripe.error.SignatureVerificationError:
            logger.warning("Stripe webhook signature verification failed")
            raise HTTPException(status_code=400, detail="Invalid signature")

        event_type = event["type"]
        data = event["data"]["object"]
        supabase = get_supabase_client()

        logger.info(f"Stripe webhook received: {event_type}")

        if event_type == "checkout.session.completed":
            user_id = data.get("metadata", {}).get("user_id")
            plan = data.get("metadata", {}).get("plan", "basic")
            subscription_id = data.get("subscription")

            if user_id:
                supabase.table("subscriptions").update({
                    "plan": plan,
                    "status": "active",
                    "stripe_subscription_id": subscription_id,
                }).eq("user_id", user_id).execute()
                logger.info(f"Checkout completed: user {user_id}, plan {plan}")

        elif event_type == "customer.subscription.updated":
            customer_id = data.get("customer")
            status = data.get("status")
            current_period_end = data.get("current_period_end")

            sub_result = (
                supabase.table("subscriptions")
                .select("user_id")
                .eq("stripe_customer_id", customer_id)
                .execute()
            )
            if sub_result.data:
                update_data = {"status": _map_stripe_status(status)}
                if current_period_end:
                    from datetime import datetime
                    update_data["current_period_end"] = datetime.fromtimestamp(
                        current_period_end
                    ).isoformat()

                supabase.table("subscriptions").update(update_data).eq(
                    "stripe_customer_id", customer_id
                ).execute()
                logger.info(f"Subscription updated for customer {customer_id}")

        elif event_type == "customer.subscription.deleted":
            customer_id = data.get("customer")
            supabase.table("subscriptions").update({
                "plan": "free",
                "status": "cancelled",
                "stripe_subscription_id": None,
            }).eq("stripe_customer_id", customer_id).execute()
            logger.info(f"Subscription deleted for customer {customer_id}")

        elif event_type == "invoice.payment_failed":
            customer_id = data.get("customer")
            supabase.table("subscriptions").update({
                "status": "past_due",
            }).eq("stripe_customer_id", customer_id).execute()
            logger.info(f"Payment failed for customer {customer_id}")

        else:
            logger.info(f"Unhandled Stripe event: {event_type}")

        return {"received": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Stripe webhook error: {str(e)}")
        raise HTTPException(status_code=500, detail="Webhook processing failed")


@router.post("/razorpay")
async def razorpay_webhook(request: Request) -> dict:
    """
    Handle Razorpay webhook events.
    Verifies signature, processes subscription lifecycle events.
    No auth required - Razorpay calls this directly.
    """
    try:
        payload = await request.body()
        signature = request.headers.get("X-Razorpay-Signature", "")

        # Verify signature
        expected = hmac.new(
            settings.RAZORPAY_KEY_SECRET.encode(),
            payload,
            hashlib.sha256,
        ).hexdigest()

        if expected != signature:
            logger.warning("Razorpay webhook signature verification failed")
            raise HTTPException(status_code=400, detail="Invalid signature")

        import json
        event_data = json.loads(payload)
        event_type = event_data.get("event", "")
        event_payload = event_data.get("payload", {})

        supabase = get_supabase_client()

        logger.info(f"Razorpay webhook received: {event_type}")

        if event_type == "subscription.activated":
            subscription = event_payload.get("subscription", {}).get("entity", {})
            customer_id = subscription.get("customer_id")

            if customer_id:
                supabase.table("subscriptions").update({
                    "status": "active",
                }).eq("razorpay_customer_id", customer_id).execute()
                logger.info(f"Subscription activated for customer {customer_id}")

        elif event_type == "subscription.charged":
            subscription = event_payload.get("subscription", {}).get("entity", {})
            customer_id = subscription.get("customer_id")
            current_end = subscription.get("current_end")

            if customer_id and current_end:
                from datetime import datetime
                supabase.table("subscriptions").update({
                    "current_period_end": datetime.fromtimestamp(current_end).isoformat(),
                    "status": "active",
                }).eq("razorpay_customer_id", customer_id).execute()
                logger.info(f"Subscription charged for customer {customer_id}")

        elif event_type == "subscription.cancelled":
            subscription = event_payload.get("subscription", {}).get("entity", {})
            customer_id = subscription.get("customer_id")

            if customer_id:
                supabase.table("subscriptions").update({
                    "plan": "free",
                    "status": "cancelled",
                    "razorpay_subscription_id": None,
                }).eq("razorpay_customer_id", customer_id).execute()
                logger.info(f"Subscription cancelled for customer {customer_id}")

        elif event_type == "subscription.halted":
            subscription = event_payload.get("subscription", {}).get("entity", {})
            customer_id = subscription.get("customer_id")

            if customer_id:
                supabase.table("subscriptions").update({
                    "status": "past_due",
                }).eq("razorpay_customer_id", customer_id).execute()
                logger.info(f"Subscription halted for customer {customer_id}")

        elif event_type == "payment.failed":
            payment = event_payload.get("payment", {}).get("entity", {})
            customer_id = payment.get("customer_id")

            if customer_id:
                supabase.table("subscriptions").update({
                    "status": "past_due",
                }).eq("razorpay_customer_id", customer_id).execute()
                logger.info(f"Payment failed for customer {customer_id}")

        else:
            logger.info(f"Unhandled Razorpay event: {event_type}")

        return {"received": True}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Razorpay webhook error: {str(e)}")
        raise HTTPException(status_code=500, detail="Webhook processing failed")


def _map_stripe_status(stripe_status: str) -> str:
    """Map Stripe subscription status to our status."""
    mapping = {
        "active": "active",
        "past_due": "past_due",
        "canceled": "cancelled",
        "unpaid": "past_due",
        "incomplete": "past_due",
        "incomplete_expired": "cancelled",
        "trialing": "active",
    }
    return mapping.get(stripe_status, "active")
