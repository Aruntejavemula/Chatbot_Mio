"""Payment models - Pydantic schemas for payment and subscription data."""

from pydantic import BaseModel
from typing import Optional


class CheckoutRequest(BaseModel):
    """Schema for creating a checkout session."""

    plan: str
    billing_cycle: str = "monthly"
    success_url: str
    cancel_url: str


class SubscriptionResponse(BaseModel):
    """Schema for subscription status response."""

    plan: str
    status: str
    current_period_end: Optional[str] = None
    cancel_at_period_end: bool = False


class RazorpayVerification(BaseModel):
    """Schema for verifying a Razorpay payment."""

    razorpay_payment_id: str
    razorpay_subscription_id: str
    razorpay_signature: str
