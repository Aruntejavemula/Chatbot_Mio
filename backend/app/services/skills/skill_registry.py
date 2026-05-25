"""Skill registry for managing available AI skills."""

import logging
from typing import Any

from app.services.skills.base_skill import BaseSkill
from app.services.skills.calculator_skill import CalculatorSkill
from app.services.skills.translator_skill import TranslatorSkill
from app.services.skills.web_search_skill import WebSearchSkill

logger = logging.getLogger(__name__)

PLAN_SKILLS: dict[str, list[str]] = {
    "free": [],
    "basic": ["web_search", "calculator", "translator"],
    "pro": ["web_search", "calculator", "translator"],
}

SKILL_METADATA: list[dict[str, str]] = [
    {"name": "web_search", "label": "Web Search", "icon": "search", "plan": "basic"},
    {"name": "calculator", "label": "Calculator", "icon": "calculate", "plan": "basic"},
    {"name": "translator", "label": "Translator", "icon": "translate", "plan": "basic"},
]


class SkillRegistry:
    """Registry for managing and accessing AI skills."""

    def __init__(self) -> None:
        """Initialize the skill registry."""
        self._skills: dict[str, BaseSkill] = {}

    def register(self, skill: BaseSkill) -> None:
        """Register a skill."""
        self._skills[skill.name] = skill
        logger.info("Registered skill: %s", skill.name)

    def get(self, name: str) -> BaseSkill | None:
        """Get a skill by name."""
        return self._skills.get(name)

    def get_for_plan(self, plan: str) -> list[BaseSkill]:
        """Get available skills for a plan."""
        skill_names = PLAN_SKILLS.get(plan, [])
        return [self._skills[n] for n in skill_names if n in self._skills]

    def get_tool_definitions(self, plan: str) -> list[dict[str, Any]]:
        """Get OpenAI-compatible tool definitions for a plan."""
        return [s.to_tool_definition() for s in self.get_for_plan(plan)]

    def get_skill_metadata(self) -> list[dict[str, str]]:
        """Get metadata for all skills."""
        return SKILL_METADATA


# Global registry instance
skill_registry = SkillRegistry()
skill_registry.register(WebSearchSkill())
skill_registry.register(CalculatorSkill())
skill_registry.register(TranslatorSkill())
