"""Skill registry for managing available AI skills."""
from typing import Any


class SkillRegistry:
    """Registry for managing and retrieving skills by name."""

    def __init__(self) -> None:
        self._skills: dict[str, Any] = {}

    def register(self, name: str, skill: Any) -> None:
        """Register a skill with the given name."""
        if not name:
            raise ValueError("Skill name cannot be empty")
        if name in self._skills:
            raise ValueError(f"Skill '{name}' is already registered")
        self._skills[name] = skill

    def get(self, name: str) -> Any:
        """Get a skill by name."""
        if name not in self._skills:
            raise KeyError(f"Skill '{name}' not found")
        return self._skills[name]

    def list_skills(self) -> list[str]:
        """List all registered skill names."""
        return sorted(self._skills.keys())

    def unregister(self, name: str) -> None:
        """Remove a skill from the registry."""
        if name not in self._skills:
            raise KeyError(f"Skill '{name}' not found")
        del self._skills[name]

    @property
    def count(self) -> int:
        """Return the number of registered skills."""
        return len(self._skills)
