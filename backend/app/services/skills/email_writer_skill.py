"""Email writer skill for generating structured email drafts."""

import logging
from typing import Any

from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)

VALID_TONES = ["formal", "casual", "friendly", "professional", "apologetic", "persuasive"]


class EmailWriterSkill(BaseSkill):
    """Generate structured email drafts based on context and parameters."""

    name = "email_writer"
    description = "Generate a structured email draft based on context, tone, and key points"
    parameters = {
        "type": "object",
        "properties": {
            "context": {
                "type": "string",
                "description": "The purpose or context of the email (e.g., 'follow up on meeting', 'request time off')",
            },
            "tone": {
                "type": "string",
                "enum": VALID_TONES,
                "description": "The tone of the email (formal, casual, friendly, professional, apologetic, persuasive)",
            },
            "recipient": {
                "type": "string",
                "description": "Who the email is addressed to (e.g., 'manager', 'client', 'team')",
            },
            "key_points": {
                "type": "string",
                "description": "Comma-separated key points to include in the email",
            },
        },
        "required": ["context", "tone"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Generate email writing instruction for AI to fill."""
        try:
            context = params.get("context", "")
            tone = params.get("tone", "professional")
            recipient = params.get("recipient", "")
            key_points = params.get("key_points", "")

            if not context:
                return {"error": "Context is required"}

            if tone not in VALID_TONES:
                tone = "professional"

            # Build structured instruction
            instruction_parts = [
                f"Write a {tone} email",
            ]

            if recipient:
                instruction_parts[0] += f" to {recipient}"

            instruction_parts.append(f"Purpose: {context}")

            if key_points:
                points = [p.strip() for p in key_points.split(",") if p.strip()]
                instruction_parts.append(f"Key points to include: {'; '.join(points)}")

            instruction_parts.append(
                "Format the email with a subject line, greeting, body paragraphs, and sign-off. "
                "Keep it concise and appropriate for the specified tone."
            )

            return {
                "instruction": "\n".join(instruction_parts),
                "context": context,
                "tone": tone,
                "recipient": recipient or "unspecified",
                "key_points": key_points,
            }
        except Exception as e:
            logger.error("Email writer skill error: %s", str(e))
            return {"error": str(e)}
