"""Stripe payments router - handles Stripe checkout and subscription management."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.post("/create-checkout")
async def create_checkout() -> dict:
    """Create a Stripe checkout session for subscription."""
    pass


@router.post("/create-portal")
async def create_portal() -> dict:
    """Create a Stripe customer portal session."""
    pass


@router.get("/status")
async def get_status() -> dict:
    """Get current Stripe subscription status."""
    pass
