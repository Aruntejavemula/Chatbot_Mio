"""Unit tests for CalculatorSkill."""
import pytest

from app.services.skills.calculator_skill import CalculatorSkill


@pytest.fixture
def calc():
    return CalculatorSkill()


class TestCalculatorSkill:
    """Tests for CalculatorSkill.evaluate."""

    def test_addition(self, calc):
        """Test basic addition."""
        assert calc.evaluate("2+2") == 4.0

    def test_subtraction(self, calc):
        """Test basic subtraction."""
        assert calc.evaluate("10-3") == 7.0

    def test_multiplication(self, calc):
        """Test basic multiplication."""
        assert calc.evaluate("4*5") == 20.0

    def test_division(self, calc):
        """Test basic division."""
        assert calc.evaluate("15/3") == 5.0

    def test_exponent(self, calc):
        """Test exponentiation."""
        assert calc.evaluate("2**3") == 8.0

    def test_negative_number(self, calc):
        """Test unary negation."""
        assert calc.evaluate("-5") == -5.0

    def test_complex_expression(self, calc):
        """Test a more complex expression."""
        assert calc.evaluate("2+3*4") == 14.0

    def test_parentheses(self, calc):
        """Test expression with parentheses."""
        assert calc.evaluate("(2+3)*4") == 20.0

    def test_invalid_expression_raises_value_error(self, calc):
        """Test that an invalid expression raises ValueError."""
        with pytest.raises(ValueError):
            calc.evaluate("abc")

    def test_division_by_zero_raises_value_error(self, calc):
        """Test that division by zero raises ValueError."""
        with pytest.raises(ValueError):
            calc.evaluate("1/0")

    def test_empty_string_raises_value_error(self, calc):
        """Test that an empty string raises ValueError."""
        with pytest.raises(ValueError):
            calc.evaluate("")
