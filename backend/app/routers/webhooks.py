"""Webhooks router - handles incoming webhooks from Stripe and Razorpay."""

from fastapi import APIRouter, Depends, HTTPException, Request

router = APIRouter()


@router.post("/stripe")
async def stripe_webhook(request: Request) -> dict:
    """Handle Stripe webhook events."""
    pass


@router.post("/razorpay")
async def razorpay_webhook(request: Request) -> dict:
    """Handle Razorpay webhook events."""
    pass
