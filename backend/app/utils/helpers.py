"""Utility helper functions for the application."""

from datetime import datetime, timezone


def get_utc_now() -> str:
    """Get current UTC timestamp as ISO string."""
    return datetime.now(timezone.utc).isoformat()


def sanitize_input(text: str) -> str:
    """Sanitize user input by stripping dangerous characters."""
    return text.strip()


def truncate_string(text: str, max_length: int = 100) -> str:
    """Truncate a string to a maximum length."""
    if len(text) <= max_length:
        return text
    return text[:max_length] + "..."
