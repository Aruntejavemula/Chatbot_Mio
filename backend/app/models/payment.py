"""Payment and subscription models for request/response validation."""

from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field


class SubscriptionResponse(BaseModel):
    """Model for subscription API responses."""

    id: str = Field(..., description="Unique subscription ID")
    user_id: str = Field(..., description="Owner user ID")
    plan: str = Field(default="free", description="Plan: free/basic/pro")
    status: str = Field(default="active", description="Status: active/cancelled/past_due")
    current_period_end: Optional[datetime] = Field(None, description="Current period end date")
    country_bucket: str = Field(default="premium", description="Pricing bucket: premium/middle/value")
    stripe_customer_id: Optional[str] = Field(None, description="Stripe customer ID")
    stripe_subscription_id: Optional[str] = Field(None, description="Stripe subscription ID")
    razorpay_customer_id: Optional[str] = Field(None, description="Razorpay customer ID")
    razorpay_subscription_id: Optional[str] = Field(None, description="Razorpay subscription ID")

    class Config:
        from_attributes = True


class SubscriptionUpdate(BaseModel):
    """Model for updating subscription."""

    plan: Optional[str] = Field(None, description="New plan")
    status: Optional[str] = Field(None, description="New status")
    current_period_end: Optional[datetime] = Field(None, description="Updated period end")
    stripe_customer_id: Optional[str] = Field(None, description="Stripe customer ID")
    stripe_subscription_id: Optional[str] = Field(None, description="Stripe subscription ID")
    razorpay_customer_id: Optional[str] = Field(None, description="Razorpay customer ID")
    razorpay_subscription_id: Optional[str] = Field(None, description="Razorpay subscription ID")


class StripeCheckoutRequest(BaseModel):
    """Model for Stripe checkout session creation."""

    plan: str = Field(..., description="Plan to subscribe: basic/pro")
    period: str = Field(default="monthly", description="Billing period: monthly/annual")


class RazorpayOrderRequest(BaseModel):
    """Model for Razorpay subscription creation."""

    plan: str = Field(..., description="Plan to subscribe: basic/pro")


class RazorpayVerifyRequest(BaseModel):
    """Model for Razorpay payment verification."""

    payment_id: str = Field(..., description="Razorpay payment ID")
    subscription_id: str = Field(..., description="Razorpay subscription ID")
    signature: str = Field(..., description="Razorpay signature for verification")
