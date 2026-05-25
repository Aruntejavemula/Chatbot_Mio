"""Mio API - FastAPI backend for Mio chatbot application."""

import asyncio

from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.gzip import GZipMiddleware
from starlette.middleware.base import BaseHTTPMiddleware

from app.config import get_settings
from app.routers import (
    admin,
    analytics,
    auth,
    chat,
    connectors,
    export,
    files,
    keys,
    memory,
    referrals,
    tokens,
    devices,
    scheduled,
    settings,
    payments_stripe,
    payments_razorpay,
    voice,
    webhooks,
)

settings_instance = get_settings()

app = FastAPI(
    title="Mio API",
    description="Backend API for Mio AI chatbot",
    version="1.0.0",
)


# Timeout middleware
class TimeoutMiddleware(BaseHTTPMiddleware):
    """Middleware to enforce request timeout."""

    def __init__(self, app: FastAPI, timeout: float = 30.0) -> None:
        super().__init__(app)
        self.timeout = timeout

    async def dispatch(self, request: Request, call_next):
        try:
            response = await asyncio.wait_for(
                call_next(request), timeout=self.timeout
            )
            return response
        except asyncio.TimeoutError:
            return Response(
                content='{"detail":"Request timeout"}',
                status_code=504,
                media_type="application/json",
            )


# Security headers middleware
class SecurityHeadersMiddleware(BaseHTTPMiddleware):
    """Middleware to add security headers to all responses."""

    async def dispatch(self, request: Request, call_next):
        response = await call_next(request)
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["X-XSS-Protection"] = "1; mode=block"
        response.headers["Referrer-Policy"] = "strict-origin-when-cross-origin"
        response.headers["Permissions-Policy"] = (
            "camera=(), microphone=(), geolocation=()"
        )
        return response


# Add middlewares (order matters - last added is executed first)
app.add_middleware(TimeoutMiddleware, timeout=30.0)
app.add_middleware(SecurityHeadersMiddleware)
app.add_middleware(GZipMiddleware, minimum_size=1000)

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
app.include_router(memory.router, prefix="/memory", tags=["Memory"])
app.include_router(voice.router, prefix="/voice", tags=["Voice"])
app.include_router(scheduled.router, prefix="/scheduled", tags=["Scheduled Tasks"])
app.include_router(admin.router, prefix="/admin", tags=["Admin"])
app.include_router(analytics.router, prefix="/analytics", tags=["Analytics"])
app.include_router(referrals.router, prefix="/referrals", tags=["Referrals"])


@app.get("/health")
async def health_check() -> dict:
    """Health check endpoint."""
    return {"status": "ok", "version": "1.0.0"}
