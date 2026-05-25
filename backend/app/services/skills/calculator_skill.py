"""Calculator skill for evaluating math expressions."""

import logging
from typing import Any

from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)

ALLOWED_BUILTINS = {
    "abs": abs,
    "round": round,
    "min": min,
    "max": max,
    "sum": sum,
    "pow": pow,
    "__builtins__": {},
}


class CalculatorSkill(BaseSkill):
    """Evaluate mathematical expressions safely."""

    name = "calculator"
    description = "Evaluate mathematical expressions safely"
    parameters = {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": "Mathematical expression to evaluate",
            },
        },
        "required": ["expression"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Execute calculator evaluation."""
        try:
            expression = params.get("expression", "")
            if not expression:
                return {"error": "Expression is required"}
            result = eval(expression, ALLOWED_BUILTINS)  # noqa: S307
            return {"result": str(result), "expression": expression}
        except Exception as e:
            logger.error("Calculator skill error: %s", str(e))
            return {"error": f"Invalid expression: {str(e)}"}
