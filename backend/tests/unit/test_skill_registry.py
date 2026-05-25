"""Unit tests for SkillRegistry."""
import pytest

from app.services.skills.skill_registry import SkillRegistry


@pytest.fixture
def registry():
    return SkillRegistry()


class TestSkillRegistry:
    """Tests for SkillRegistry."""

    def test_register_and_get(self, registry):
        """Test registering a skill and retrieving it."""
        skill = object()
        registry.register("test_skill", skill)
        assert registry.get("test_skill") is skill

    def test_list_skills_empty(self, registry):
        """Test listing skills when registry is empty."""
        assert registry.list_skills() == []

    def test_list_skills_sorted(self, registry):
        """Test that list_skills returns sorted names."""
        registry.register("beta", "b")
        registry.register("alpha", "a")
        registry.register("gamma", "g")
        assert registry.list_skills() == ["alpha", "beta", "gamma"]

    def test_unregister(self, registry):
        """Test unregistering a skill."""
        registry.register("skill", "value")
        registry.unregister("skill")
        assert registry.list_skills() == []

    def test_count(self, registry):
        """Test the count property."""
        assert registry.count == 0
        registry.register("one", 1)
        assert registry.count == 1
        registry.register("two", 2)
        assert registry.count == 2

    def test_duplicate_registration_raises(self, registry):
        """Test that registering a duplicate name raises ValueError."""
        registry.register("skill", "value")
        with pytest.raises(ValueError, match="already registered"):
            registry.register("skill", "other")

    def test_get_nonexistent_raises(self, registry):
        """Test that getting a nonexistent skill raises KeyError."""
        with pytest.raises(KeyError, match="not found"):
            registry.get("nonexistent")

    def test_unregister_nonexistent_raises(self, registry):
        """Test that unregistering a nonexistent skill raises KeyError."""
        with pytest.raises(KeyError, match="not found"):
            registry.unregister("nonexistent")

    def test_register_empty_name_raises(self, registry):
        """Test that registering with empty name raises ValueError."""
        with pytest.raises(ValueError, match="cannot be empty"):
            registry.register("", "value")
