"""Unit tests for CostService."""
import pytest

from app.services.cost_service import CostService


@pytest.fixture
def service():
    return CostService()


class TestCalculateCost:
    """Tests for CostService.calculate_cost."""

    def test_known_model_gpt4o(self, service):
        """Test cost calculation for gpt-4o model."""
        cost = service.calculate_cost('gpt-4o', 1000, 500)
        expected = 1000 * 0.0000025 + 500 * 0.00001
        assert cost == pytest.approx(expected)

    def test_known_model_deepseek_chat(self, service):
        """Test cost calculation for deepseek-chat model."""
        cost = service.calculate_cost('deepseek-chat', 2000, 1000)
        expected = 2000 * 0.00000027 + 1000 * 0.0000011
        assert cost == pytest.approx(expected)

    def test_known_model_claude_sonnet(self, service):
        """Test cost calculation for claude-sonnet-4-5 model."""
        cost = service.calculate_cost('claude-sonnet-4-5', 500, 200)
        expected = 500 * 0.000003 + 200 * 0.000015
        assert cost == pytest.approx(expected)

    def test_unknown_model_uses_default(self, service):
        """Test that unknown models use the default rate."""
        cost = service.calculate_cost('unknown-model', 1000, 500)
        expected = 1000 * 0.000001 + 500 * 0.000002
        assert cost == pytest.approx(expected)

    def test_zero_tokens(self, service):
        """Test with zero tokens returns zero cost."""
        cost = service.calculate_cost('gpt-4o', 0, 0)
        assert cost == 0.0


class TestFormatCost:
    """Tests for CostService.format_cost."""

    def test_small_cost_below_threshold(self, service):
        """Test that very small costs show as <$0.001."""
        result = service.format_cost(0.0001)
        assert result == '<$0.001'

    def test_cost_at_threshold(self, service):
        """Test cost at the $0.001 threshold."""
        result = service.format_cost(0.001)
        assert result == '$0.001'

    def test_larger_cost(self, service):
        """Test formatting a larger cost."""
        result = service.format_cost(1.234)
        assert result == '$1.234'

    def test_zero_cost(self, service):
        """Test formatting zero cost."""
        result = service.format_cost(0.0)
        assert result == '<$0.001'
