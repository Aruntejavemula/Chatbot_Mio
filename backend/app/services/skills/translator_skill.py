"""Translator skill for language translation."""

import logging
from typing import Any

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
        """Execute translation (delegates to AI)."""
        try:
            text = params.get("text", "")
            target = params.get("target_language", "")
            if not text or not target:
                return {"error": "Text and target_language are required"}
            return {
                "instruction": f"Translate the following to {target}: {text}",
                "text": text,
                "target_language": target,
            }
        except Exception as e:
            logger.error("Translator skill error: %s", str(e))
            return {"error": str(e)}
