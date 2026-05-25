"""Token service - handles token usage tracking and limit enforcement."""


class TokenService:
    """Service for tracking and enforcing token usage limits."""

    async def get_usage(self, user_id: str) -> dict:
        """Get current token usage for a user."""
        pass

    async def increment_usage(self, user_id: str, tokens: int) -> None:
        """Increment token usage for a user."""
        pass

    async def check_limit(self, user_id: str, plan: str) -> bool:
        """Check if user has exceeded their token limit."""
        pass

    async def reset_usage(self, user_id: str) -> None:
        """Reset token usage for a user (called on billing cycle)."""
        pass
