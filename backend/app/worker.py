"""Celery worker configuration for async task processing."""

import logging

from celery import Celery
from celery.schedules import crontab

from app.config import get_settings

logger = logging.getLogger(__name__)

settings = get_settings()

celery_app = Celery(
    "mio",
    broker=settings.UPSTASH_REDIS_URL,
    backend=settings.UPSTASH_REDIS_URL,
)

celery_app.conf.update(
    task_serializer="json",
    result_serializer="json",
    accept_content=["json"],
    task_track_started=True,
    task_ack_late=True,
    worker_prefetch_multiplier=1,
    result_expires=3600,
    beat_schedule={
        "trial-reminders": {
            "task": "app.tasks.trial_reminders.send_trial_reminders",
            "schedule": crontab(hour=9, minute=0),
        },
    },
)
