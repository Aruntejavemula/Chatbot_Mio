"""Translator skill for language translation."""

import logging
from typing import Any

import httpx

from app.config import get_settings
from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)


class TranslatorSkill(BaseSkill):
    """Translate text between languages."""

    name = "translator"
    description = "Translate text between languages"
    parameters = {
        "type": "object",
        "properties": {
            "text": {
                "type": "string",
                "description": "Text to translate",
            },
            "target_language": {
                "type": "string",
                "description": "Target language name (e.g., Spanish, French)",
            },
        },
        "required": ["text", "target_language"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Execute translation using DeepSeek API if available, otherwise fallback."""
        try:
            text = params.get("text", "")
            target = params.get("target_language", "")
            if not text or not target:
                return {"error": "Text and target_language are required"}

            settings = get_settings()

            if settings.DEEPSEEK_API_KEY:
                return await self._translate_with_deepseek(text, target, settings.DEEPSEEK_API_KEY)

            # Fallback: return instruction for the AI to handle
            return {
                "instruction": f"Translate the following text to {target}. Only provide the translation, no explanations.",
                "text": text,
                "target_language": target,
            }
        except Exception as e:
            logger.error("Translator skill error: %s", str(e))
            return {"error": str(e)}

    async def _translate_with_deepseek(
        self, text: str, target_language: str, api_key: str
    ) -> dict[str, Any]:
        """Translate text using DeepSeek API."""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    "https://api.deepseek.com/v1/chat/completions",
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "deepseek-chat",
                        "messages": [
                            {
                                "role": "system",
                                "content": f"You are a professional translator. Translate the user's text to {target_language}. Only provide the translation, no explanations or additional text.",
                            },
                            {
                                "role": "user",
                                "content": text,
                            },
                        ],
                        "temperature": 0.3,
                        "max_tokens": 2000,
                    },
                )
                response.raise_for_status()
                data = response.json()
                translation = data["choices"][0]["message"]["content"].strip()
                return {
                    "translation": translation,
                    "text": text,
                    "target_language": target_language,
                    "provider": "deepseek",
                }
        except httpx.HTTPStatusError as e:
            logger.error("DeepSeek API error: %s", str(e))
            # Fallback to instruction format on API failure
            return {
                "instruction": f"Translate the following text to {target_language}. Only provide the translation, no explanations.",
                "text": text,
                "target_language": target_language,
            }
        except Exception as e:
            logger.error("DeepSeek translation error: %s", str(e))
            return {
                "instruction": f"Translate the following text to {target_language}. Only provide the translation, no explanations.",
                "text": text,
                "target_language": target_language,
            }
