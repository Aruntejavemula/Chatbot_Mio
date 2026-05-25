"""Email service - transactional emails via Resend."""

import logging

import resend

from app.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()
resend.api_key = settings.RESEND_API_KEY

FROM_EMAIL = "Mio <noreply@yourdomain.com>"


class EmailService:
    """Service for sending transactional emails. No marketing emails."""

    async def send_welcome_email(self, to_email: str, name: str) -> bool:
        """
        Send welcome email after sign up.

        Args:
            to_email: Recipient email
            name: User's display name

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            resend.Emails.send({
                "from": FROM_EMAIL,
                "to": to_email,
                "subject": "Welcome to Mio",
                "html": (
                    f"<h2>Welcome to Mio, {name}!</h2>"
                    "<p>Think. Not yap.</p>"
                    "<p>You now have access to every AI model "
                    "through one clean interface.</p>"
                    "<p>Get started by adding your first API key "
                    "in settings.</p>"
                    "<br>"
                    "<p>The Mio Team</p>"
                ),
            })
            logger.info(f"Welcome email sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send welcome email: {str(e)}")
            return False

    async def send_subscription_activated(
        self, to_email: str, name: str, plan: str
    ) -> bool:
        """
        Send email when subscription activates.

        Args:
            to_email: Recipient email
            name: User's display name
            plan: Activated plan name

        Returns:
            True if sent successfully, False otherwise
        """
        plan_benefits = {
            "basic": "Google Drive sync + all models",
            "pro": "3M tokens + full sync + skills",
        }
        benefits = plan_benefits.get(plan, "")

        try:
            resend.Emails.send({
                "from": FROM_EMAIL,
                "to": to_email,
                "subject": f"Mio {plan.capitalize()} activated",
                "html": (
                    f"<h2>You're on Mio {plan.capitalize()}</h2>"
                    f"<p>Hi {name},</p>"
                    f"<p>Your {plan} plan is now active.</p>"
                    f"<p>{benefits}</p>"
                    "<p>Manage your subscription anytime in Settings.</p>"
                    "<br>"
                    "<p>The Mio Team</p>"
                ),
            })
            logger.info(f"Subscription email sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send subscription email: {str(e)}")
            return False

    async def send_payment_failed(self, to_email: str, name: str) -> bool:
        """
        Send email when payment fails.

        Args:
            to_email: Recipient email
            name: User's display name

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            resend.Emails.send({
                "from": FROM_EMAIL,
                "to": to_email,
                "subject": "Payment failed - Action required",
                "html": (
                    f"<h2>Payment issue, {name}</h2>"
                    "<p>Your recent payment failed.</p>"
                    "<p>Update your payment method to keep your "
                    "subscription active.</p>"
                    "<p>Your account will downgrade to free tier "
                    "if not resolved.</p>"
                    "<br>"
                    "<p>The Mio Team</p>"
                ),
            })
            logger.info(f"Payment failed email sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send payment failed email: {str(e)}")
            return False

    async def send_token_limit_warning(
        self, to_email: str, name: str, percent_used: int
    ) -> bool:
        """
        Send email when user hits 80% of monthly tokens.

        Args:
            to_email: Recipient email
            name: User's display name
            percent_used: Percentage of tokens used

        Returns:
            True if sent successfully, False otherwise
        """
        try:
            resend.Emails.send({
                "from": FROM_EMAIL,
                "to": to_email,
                "subject": f"You've used {percent_used}% of your tokens",
                "html": (
                    "<h2>Token usage update</h2>"
                    f"<p>Hi {name},</p>"
                    f"<p>You have used {percent_used}% of your monthly "
                    "token allowance.</p>"
                    "<p>Add your own API keys in settings to continue "
                    "after your limit.</p>"
                    "<p>Tokens reset on the 1st of each month.</p>"
                    "<br>"
                    "<p>The Mio Team</p>"
                ),
            })
            logger.info(f"Token warning email sent to {to_email}")
            return True
        except Exception as e:
            logger.error(f"Failed to send token warning email: {str(e)}")
            return False


email_service = EmailService()
