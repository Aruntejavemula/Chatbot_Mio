"""Email service - handles sending transactional emails via Resend."""


class EmailService:
    """Service for sending transactional emails."""

    def __init__(self, api_key: str) -> None:
        """Initialize email service with Resend API key."""
        self.api_key = api_key

    async def send_welcome_email(self, to: str, name: str) -> bool:
        """Send a welcome email to a new user."""
        pass

    async def send_subscription_email(self, to: str, plan: str) -> bool:
        """Send a subscription confirmation email."""
        pass

    async def send_cancellation_email(self, to: str) -> bool:
        """Send a subscription cancellation email."""
        pass
