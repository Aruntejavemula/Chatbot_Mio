"""Provider routing with circuit breaker integration."""

import logging
from typing import Any

from app.services.circuit_breaker import circuit_breaker

logger = logging.getLogger(__name__)

# Provider priority order (cheapest + fastest first)
PROVIDER_PRIORITY: list[str] = [
    "deepseek",
    "gemini",
    "groq",
    "mistral",
    "openai",
    "anthropic",
    "openrouter",
]

# Default model per provider for fallback routing
DEFAULT_MODELS: dict[str, str] = {
    "deepseek": "deepseek-chat",
    "gemini": "gemini-2.5-flash",
    "groq": "llama-3.1-70b-versatile",
    "mistral": "mistral-large-latest",
    "openai": "gpt-4o-mini",
    "anthropic": "claude-3-5-haiku-20241022",
    "openrouter": "openai/gpt-4o-mini",
}


class ProviderRouter:
    """Routes AI requests to healthy providers with fallback logic.

    When using platform tokens (not BYOK), the router checks circuit
    breaker state and falls back to alternative providers if the
    preferred one is unavailable.
    """

    async def route(
        self,
        preferred_provider: str,
        preferred_model: str,
        byok: bool,
        user_id: str,
    ) -> tuple[str, str]:
        """Route a request to the best available provider.

        Args:
            preferred_provider: User's preferred provider.
            preferred_model: User's preferred model.
            byok: Whether the user is using their own API key.
            user_id: The requesting user's ID.

        Returns:
            Tuple of (provider, model) to use.

        Raises:
            ServiceUnavailableError: If all providers are unavailable.
        """
        if byok:
            return preferred_provider, preferred_model

        if await circuit_breaker.can_request(preferred_provider):
            return preferred_provider, preferred_model

        logger.warning(
            "Provider %s circuit open for user=%s, finding fallback",
            preferred_provider,
            user_id,
        )

        healthy_providers = await circuit_breaker.get_healthy_providers(
            PROVIDER_PRIORITY
        )

        if not healthy_providers:
            logger.error(
                "All providers unavailable for user=%s", user_id
            )
            raise ServiceUnavailableError(
                "All AI providers temporarily unavailable. "
                "Try using your own API key."
            )

        fallback_provider = healthy_providers[0]
        fallback_model = DEFAULT_MODELS.get(fallback_provider, "")

        logger.info(
            "Routed user=%s from %s to fallback %s/%s",
            user_id,
            preferred_provider,
            fallback_provider,
            fallback_model,
        )

        return fallback_provider, fallback_model


class ServiceUnavailableError(Exception):
    """Raised when no AI providers are available."""

    pass


# Global provider router instance
provider_router = ProviderRouter()
