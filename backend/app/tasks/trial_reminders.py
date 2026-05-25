"""Celery task for sending trial expiration reminders."""

import logging
from typing import Any

from app.worker import celery_app

logger = logging.getLogger(__name__)


@celery_app.task(bind=True)
def send_trial_reminders(self) -> dict[str, Any]:
    """Send reminders to users whose trials are expiring.

    Queries trial users and sends reminders at:
    - 7 days remaining
    - 2 days remaining
    - 0 days (trial expired)

    Returns:
        Dictionary with task execution results.
    """
    try:
        logger.info("Starting trial reminder task")

        # Placeholder: query trial users from database
        # In production, this would query Supabase for users with active trials
        reminder_counts = {
            "7_day": 0,
            "2_day": 0,
            "expired": 0,
        }

        # Placeholder: find users with 7 days remaining
        logger.info("Checking for users with 7 days remaining on trial")
        # Would query: subscriptions WHERE plan='trial' AND trial_end_at = now() + 7 days
        # For each user, send reminder email

        # Placeholder: find users with 2 days remaining
        logger.info("Checking for users with 2 days remaining on trial")
        # Would query: subscriptions WHERE plan='trial' AND trial_end_at = now() + 2 days
        # For each user, send urgent reminder email

        # Placeholder: find users whose trial expired today
        logger.info("Checking for users whose trial expired today")
        # Would query: subscriptions WHERE plan='trial' AND trial_end_at <= now()
        # For each user, send expiration notice and downgrade to free

        logger.info(
            "Trial reminders completed: 7-day=%d, 2-day=%d, expired=%d",
            reminder_counts["7_day"],
            reminder_counts["2_day"],
            reminder_counts["expired"],
        )

        return {
            "status": "done",
            "reminders_sent": reminder_counts,
        }
    except Exception as exc:
        logger.error("Trial reminder task failed: %s", str(exc))
        raise
