"""Mio API - FastAPI backend for Mio chatbot application."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import get_settings
from app.routers import (
    auth,
    chat,
    connectors,
    export,
    files,
    keys,
    tokens,
    devices,
    settings,
    payments_stripe,
    payments_razorpay,
    webhooks,
)

settings_instance = get_settings()

app = FastAPI(
    title="Mio API",
    description="Backend API for Mio AI chatbot",
    version="1.0.0",
)

# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings_instance.ALLOWED_ORIGINS.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth.router, prefix="/auth", tags=["Auth"])
app.include_router(chat.router, prefix="/chat", tags=["Chat"])
app.include_router(export.router, prefix="/export", tags=["Export"])
app.include_router(files.router, prefix="/files", tags=["Files"])
app.include_router(keys.router, prefix="/keys", tags=["Keys"])
app.include_router(tokens.router, prefix="/tokens", tags=["Tokens"])
app.include_router(devices.router, prefix="/devices", tags=["Devices"])
app.include_router(settings.router, prefix="/settings", tags=["Settings"])
app.include_router(payments_stripe.router, prefix="/payments/stripe", tags=["Payments - Stripe"])
app.include_router(payments_razorpay.router, prefix="/payments/razorpay", tags=["Payments - Razorpay"])
app.include_router(webhooks.router, prefix="/webhooks", tags=["Webhooks"])
app.include_router(connectors.router, prefix="/connectors", tags=["Connectors"])


@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {"status": "ok", "version": "1.0.0"}
