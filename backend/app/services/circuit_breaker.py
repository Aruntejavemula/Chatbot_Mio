"""Circuit breaker pattern for AI provider resilience."""

import logging
import time
from typing import Any

from app.config import get_settings

logger = logging.getLogger(__name__)

# Circuit breaker states
STATE_CLOSED = "closed"
STATE_OPEN = "open"
STATE_HALF_OPEN = "half_open"

# Configuration constants
FAILURE_THRESHOLD: int = 3
RECOVERY_TIMEOUT_SECONDS: int = 60
HALF_OPEN_MAX_CALLS: int = 1


class CircuitBreaker:
    """In-memory circuit breaker for AI provider health tracking.

    Tracks failures per provider and opens the circuit after
    consecutive failures exceed the threshold. After a recovery
    timeout, allows a single test call (half-open state).
    """

    def __init__(self) -> None:
        """Initialize circuit breaker with empty state."""
        self._states: dict[str, dict[str, Any]] = {}

    def _get_provider_state(self, provider: str) -> dict[str, Any]:
        """Get or create state for a provider.

        Args:
            provider: The provider name.

        Returns:
            Dictionary with state, failures, last_failure, opened_at.
        """
        if provider not in self._states:
            self._states[provider] = {
                "state": STATE_CLOSED,
                "failures": 0,
                "last_failure": 0.0,
                "opened_at": 0.0,
            }
        return self._states[provider]

    async def can_request(self, provider: str) -> bool:
        """Check if a request can be made to the provider.

        Args:
            provider: The provider name to check.

        Returns:
            True if the request is allowed, False if circuit is open.
        """
        state = self._get_provider_state(provider)

        if state["state"] == STATE_CLOSED:
            return True

        if state["state"] == STATE_OPEN:
            elapsed = time.time() - state["opened_at"]
            if elapsed >= RECOVERY_TIMEOUT_SECONDS:
                state["state"] = STATE_HALF_OPEN
                logger.info(
                    "Circuit breaker for %s moved to HALF_OPEN after %ds",
                    provider,
                    int(elapsed),
                )
                return True
            return False

        if state["state"] == STATE_HALF_OPEN:
            return True

        return False

    async def record_success(self, provider: str) -> None:
        """Record a successful request to a provider.

        Resets the circuit to closed state.

        Args:
            provider: The provider name.
        """
        state = self._get_provider_state(provider)
        if state["state"] != STATE_CLOSED:
            logger.info("Circuit breaker for %s reset to CLOSED", provider)
        state["state"] = STATE_CLOSED
        state["failures"] = 0
        state["last_failure"] = 0.0
        state["opened_at"] = 0.0

    async def record_failure(self, provider: str) -> None:
        """Record a failed request to a provider.

        Opens the circuit if failures exceed threshold.

        Args:
            provider: The provider name.
        """
        state = self._get_provider_state(provider)
        state["failures"] += 1
        state["last_failure"] = time.time()

        if state["failures"] >= FAILURE_THRESHOLD:
            state["state"] = STATE_OPEN
            state["opened_at"] = time.time()
            logger.warning(
                "Circuit breaker OPENED for %s after %d failures",
                provider,
                state["failures"],
            )

    async def get_healthy_providers(
        self, providers: list[str]
    ) -> list[str]:
        """Filter providers to only those with closed or half-open circuits.

        Maintains original order (preferred providers first).

        Args:
            providers: List of provider names to check.

        Returns:
            Filtered list of healthy providers.
        """
        healthy: list[str] = []
        for provider in providers:
            if await self.can_request(provider):
                healthy.append(provider)
        return healthy

    async def get_provider_health(self) -> dict[str, str]:
        """Get health status of all tracked providers.

        Returns:
            Dictionary mapping provider names to status strings.
        """
        result: dict[str, str] = {}
        for provider, state in self._states.items():
            if state["state"] == STATE_CLOSED:
                result[provider] = "healthy"
            elif state["state"] == STATE_HALF_OPEN:
                result[provider] = "degraded"
            else:
                result[provider] = "unhealthy"
        return result


# Global circuit breaker instance
circuit_breaker = CircuitBreaker()
