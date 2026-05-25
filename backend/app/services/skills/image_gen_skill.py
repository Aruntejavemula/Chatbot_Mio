"""Image generation skill using OpenAI DALL-E 3 API."""

import logging
from typing import Any

import httpx

from app.config import get_settings
from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)


class ImageGenSkill(BaseSkill):
    """Skill for generating images using DALL-E 3."""

    name = "image_generation"
    description = "Generate images from text descriptions using DALL-E 3"
    parameters = {
        "type": "object",
        "properties": {
            "prompt": {
                "type": "string",
                "description": "Text description of the image to generate",
            },
            "size": {
                "type": "string",
                "enum": ["1024x1024", "1792x1024", "1024x1792"],
                "description": "Image size",
            },
        },
        "required": ["prompt"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Generate an image using DALL-E 3.

        Args:
            params: Dictionary with 'prompt' and optional 'size'.

        Returns:
            Dictionary with image_url, prompt, and revised_prompt.
        """
        prompt = params.get("prompt", "")
        size = params.get("size", "1024x1024")

        if not prompt:
            return {"error": "Prompt is required"}

        settings = get_settings()
        api_key = settings.OPENAI_API_KEY

        if not api_key:
            return {"error": "OpenAI API key not configured"}

        try:
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    "https://api.openai.com/v1/images/generations",
                    headers={
                        "Authorization": f"Bearer {api_key}",
                        "Content-Type": "application/json",
                    },
                    json={
                        "model": "dall-e-3",
                        "prompt": prompt,
                        "n": 1,
                        "size": size,
                    },
                )

                if response.status_code != 200:
                    logger.error("DALL-E API error: %s", response.text)
                    return {"error": f"Image generation failed: {response.status_code}"}

                data = response.json()
                image_data = data["data"][0]

                return {
                    "image_url": image_data["url"],
                    "prompt": prompt,
                    "revised_prompt": image_data.get("revised_prompt", prompt),
                }

        except httpx.TimeoutException:
            logger.error("DALL-E API timeout")
            return {"error": "Image generation timed out"}
        except Exception as e:
            logger.error("Image generation error: %s", str(e))
            return {"error": f"Image generation failed: {str(e)}"}
