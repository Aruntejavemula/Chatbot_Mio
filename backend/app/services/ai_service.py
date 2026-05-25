"""AI service - handles AI model interactions and streaming responses."""

from typing import AsyncGenerator


class AIService:
    """Service for interacting with AI models."""

    async def stream_response(
        self, messages: list, model: str, api_key: str
    ) -> AsyncGenerator[str, None]:
        """Stream a response from the AI model."""
        pass

    async def count_tokens(self, text: str, model: str) -> int:
        """Count tokens in a text string for a given model."""
        pass

    def get_available_models(self) -> list[str]:
        """Get list of available AI models."""
        pass
