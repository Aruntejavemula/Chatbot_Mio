"""Authentication router for email/password auth endpoints."""
from __future__ import annotations

import logging
import time

from fastapi import APIRouter, HTTPException, Request
from pydantic import BaseModel, EmailStr, Field

logger = logging.getLogger(__name__)

router = APIRouter()

# Rate limit constants for auth endpoints (IP-based)
AUTH_RATE_LIMIT_MAX: int = 5
AUTH_RATE_LIMIT_WINDOW: int = 60


class _AuthRateLimiter:
    """IP-based rate limiter for unauthenticated auth endpoints.

    Uses in-memory storage with a sliding window approach.
    In production, this would use Upstash Redis for distributed limiting.
    """

    def __init__(self) -> None:
        """Initialize the rate limiter with an empty request store."""
        self._requests: dict[str, list[float]] = {}

    def check_rate_limit(
        self, key: str, max_requests: int, window_seconds: int
    ) -> bool:
        """Check if a request is within the rate limit.

        Args:
            key: The unique key for rate limiting (e.g., client IP).
            max_requests: Maximum number of requests allowed.
            window_seconds: The time window in seconds.

        Returns:
            True if the request is allowed, False if rate limited.
        """
        now = time.time()
        cutoff = now - window_seconds

        if key in self._requests:
            self._requests[key] = [
                ts for ts in self._requests[key] if ts > cutoff
            ]
        else:
            self._requests[key] = []

        if len(self._requests[key]) >= max_requests:
            return False

        self._requests[key].append(now)
        return True


_auth_rate_limiter = _AuthRateLimiter()


def _enforce_auth_rate_limit(request: Request) -> None:
    """Enforce IP-based rate limiting for auth endpoints.

    Args:
        request: The incoming FastAPI request.

    Raises:
        HTTPException: If the rate limit is exceeded (429).
    """
    client_host = request.client.host if request.client else "unknown"
    key = f"auth_rate_limit:{client_host}"

    if not _auth_rate_limiter.check_rate_limit(
        key, AUTH_RATE_LIMIT_MAX, AUTH_RATE_LIMIT_WINDOW
    ):
        logger.warning(
            "Auth rate limit exceeded for IP=%s (limit=%d/%ds)",
            client_host,
            AUTH_RATE_LIMIT_MAX,
            AUTH_RATE_LIMIT_WINDOW,
        )
        raise HTTPException(
            status_code=429,
            detail="Rate limit exceeded. Please try again later.",
        )


# --- Request/Response Models ---


class SignupRequest(BaseModel):
    """Request model for user signup."""

    email: EmailStr
    password: str = Field(..., min_length=8)
    name: str = Field(..., min_length=1, max_length=100)


class UserResponse(BaseModel):
    """User data in auth responses."""

    id: str
    email: str
    name: str
    email_verified: bool


class SubscriptionResponse(BaseModel):
    """Subscription data in auth responses."""

    plan: str
    status: str


class SignupResponse(BaseModel):
    """Response model for successful signup."""

    access_token: str
    user: UserResponse
    subscription: SubscriptionResponse


class LoginRequest(BaseModel):
    """Request model for user login."""

    email: EmailStr
    password: str = Field(..., min_length=1)


class LoginResponse(BaseModel):
    """Response model for successful login."""

    access_token: str
    user: UserResponse
    subscription: SubscriptionResponse


class ForgotPasswordRequest(BaseModel):
    """Request model for forgot password."""

    email: EmailStr


class ResetPasswordRequest(BaseModel):
    """Request model for password reset."""

    token: str = Field(..., min_length=1)
    new_password: str = Field(..., min_length=8)


class ResendVerificationRequest(BaseModel):
    """Request model for resending verification email."""

    email: EmailStr


class MessageResponse(BaseModel):
    """Generic message response."""

    message: str


# --- Endpoints ---


@router.post(
    "/signup",
    response_model=SignupResponse,
    summary="Register a new user with email and password",
    status_code=201,
)
async def signup(body: SignupRequest, request: Request) -> SignupResponse:
    """Register a new user with email and password.

    Calls Supabase auth.sign_up (placeholder) and returns access token
    along with user and subscription info.
    """
    _enforce_auth_rate_limit(request)

    logger.info("Signup attempt for email=%s", body.email)

    # Placeholder: In production, call Supabase auth.sign_up
    # supabase.auth.sign_up({"email": body.email, "password": body.password})
    placeholder_user_id = "usr_placeholder_id"

    logger.info("User created successfully: user_id=%s", placeholder_user_id)

    return SignupResponse(
        access_token="placeholder_access_token",
        user=UserResponse(
            id=placeholder_user_id,
            email=body.email,
            name=body.name,
            email_verified=False,
        ),
        subscription=SubscriptionResponse(
            plan="free",
            status="active",
        ),
    )


@router.post(
    "/login",
    response_model=LoginResponse,
    summary="Login with email and password",
)
async def login(body: LoginRequest, request: Request) -> LoginResponse:
    """Authenticate a user with email and password.

    Calls Supabase sign_in_with_password (placeholder) and checks
    the email_verified flag before returning the access token.
    """
    _enforce_auth_rate_limit(request)

    logger.info("Login attempt for email=%s", body.email)

    # Placeholder: In production, call Supabase sign_in_with_password
    # response = supabase.auth.sign_in_with_password(...)
    placeholder_user_id = "usr_placeholder_id"
    placeholder_email_verified = True

    if not placeholder_email_verified:
        logger.warning(
            "Login failed: email not verified for email=%s", body.email
        )
        raise HTTPException(
            status_code=403,
            detail="Email not verified. Please check your inbox.",
        )

    logger.info("Login successful for user_id=%s", placeholder_user_id)

    return LoginResponse(
        access_token="placeholder_access_token",
        user=UserResponse(
            id=placeholder_user_id,
            email=body.email,
            name="Placeholder User",
            email_verified=placeholder_email_verified,
        ),
        subscription=SubscriptionResponse(
            plan="free",
            status="active",
        ),
    )


@router.post(
    "/forgot-password",
    response_model=MessageResponse,
    summary="Request a password reset email",
)
async def forgot_password(
    body: ForgotPasswordRequest, request: Request
) -> MessageResponse:
    """Request a password reset email.

    Always returns 200 with a generic message for security,
    even if the email is not found in the system.
    """
    _enforce_auth_rate_limit(request)

    logger.info("Password reset requested for email=%s", body.email)

    # Placeholder: In production, call Supabase reset_password_email
    # supabase.auth.reset_password_email(body.email)

    return MessageResponse(
        message="If an account with that email exists, a reset link has been sent."
    )


@router.post(
    "/reset-password",
    response_model=MessageResponse,
    summary="Reset password with token",
)
async def reset_password(
    body: ResetPasswordRequest, request: Request
) -> MessageResponse:
    """Reset the user's password using a reset token.

    Validates the new password meets minimum length requirements
    and calls Supabase update_user (placeholder).
    """
    _enforce_auth_rate_limit(request)

    logger.info("Password reset attempt with token")

    # Placeholder: In production, verify token and call Supabase update_user
    # supabase.auth.update_user({"password": body.new_password})

    logger.info("Password reset successful")

    return MessageResponse(message="Password has been reset successfully.")


@router.post(
    "/resend-verification",
    response_model=MessageResponse,
    summary="Resend email verification link",
)
async def resend_verification(
    body: ResendVerificationRequest, request: Request
) -> MessageResponse:
    """Resend the email verification link.

    Always returns 200 with a generic message for security,
    even if the email is not found in the system.
    """
    _enforce_auth_rate_limit(request)

    logger.info("Verification resend requested for email=%s", body.email)

    # Placeholder: In production, call Supabase resend verification
    # supabase.auth.resend({"type": "signup", "email": body.email})

    return MessageResponse(
        message="If an account with that email exists, a verification link has been sent."
    )
