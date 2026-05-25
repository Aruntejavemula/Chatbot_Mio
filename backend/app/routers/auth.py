"""Authentication router - handles Google/Apple sign-in and session management."""

from fastapi import APIRouter, Depends, HTTPException

router = APIRouter()


@router.post("/google")
async def google_sign_in() -> dict:
    """Sign in with Google OAuth."""
    pass


@router.post("/apple")
async def apple_sign_in() -> dict:
    """Sign in with Apple OAuth."""
    pass


@router.post("/signout")
async def sign_out() -> dict:
    """Sign out and invalidate session."""
    pass


@router.get("/profile")
async def get_profile() -> dict:
    """Get current user profile."""
    pass
