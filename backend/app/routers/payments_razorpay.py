"""Razorpay payments router - handles Razorpay subscription management for India."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.post("/create-subscription")
async def create_subscription() -> dict:
    """Create a Razorpay subscription."""
    pass


@router.post("/verify-payment")
async def verify_payment() -> dict:
    """Verify a Razorpay payment signature."""
    pass
