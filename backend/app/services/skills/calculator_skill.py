"""Calculator skill using AST-based safe expression evaluator."""

import ast
import logging
import math
import operator
from typing import Any

from app.services.skills.base_skill import BaseSkill

logger = logging.getLogger(__name__)

# Supported binary operators
BINARY_OPS = {
    ast.Add: operator.add,
    ast.Sub: operator.sub,
    ast.Mult: operator.mul,
    ast.Div: operator.truediv,
    ast.Pow: operator.pow,
    ast.Mod: operator.mod,
    ast.FloorDiv: operator.floordiv,
}

# Supported unary operators
UNARY_OPS = {
    ast.UAdd: operator.pos,
    ast.USub: operator.neg,
}

# Supported math functions
MATH_FUNCTIONS = {
    "sqrt": math.sqrt,
    "sin": math.sin,
    "cos": math.cos,
    "tan": math.tan,
    "log": math.log,
    "log10": math.log10,
    "ceil": math.ceil,
    "floor": math.floor,
    "abs": abs,
    "round": round,
}

# Supported math constants
MATH_CONSTANTS = {
    "pi": math.pi,
    "e": math.e,
}


def _safe_eval(node: ast.AST) -> float:
    """Recursively evaluate an AST node safely."""
    if isinstance(node, ast.Expression):
        return _safe_eval(node.body)
    elif isinstance(node, ast.Constant):
        if isinstance(node.value, (int, float)):
            return node.value
        raise ValueError(f"Unsupported constant: {node.value}")
    elif isinstance(node, ast.BinOp):
        op_type = type(node.op)
        if op_type not in BINARY_OPS:
            raise ValueError(f"Unsupported operator: {op_type.__name__}")
        left = _safe_eval(node.left)
        right = _safe_eval(node.right)
        return BINARY_OPS[op_type](left, right)
    elif isinstance(node, ast.UnaryOp):
        op_type = type(node.op)
        if op_type not in UNARY_OPS:
            raise ValueError(f"Unsupported unary operator: {op_type.__name__}")
        operand = _safe_eval(node.operand)
        return UNARY_OPS[op_type](operand)
    elif isinstance(node, ast.Call):
        if not isinstance(node.func, ast.Name):
            raise ValueError("Only simple function calls are supported")
        func_name = node.func.id
        if func_name not in MATH_FUNCTIONS:
            raise ValueError(f"Unsupported function: {func_name}")
        args = [_safe_eval(arg) for arg in node.args]
        return MATH_FUNCTIONS[func_name](*args)
    elif isinstance(node, ast.Name):
        if node.id in MATH_CONSTANTS:
            return MATH_CONSTANTS[node.id]
        raise ValueError(f"Unsupported name: {node.id}")
    else:
        raise ValueError(f"Unsupported expression type: {type(node).__name__}")


def safe_evaluate(expression: str) -> float:
    """Parse and evaluate a math expression safely using AST."""
    tree = ast.parse(expression, mode="eval")
    return _safe_eval(tree)


class CalculatorSkill(BaseSkill):
    """Evaluate mathematical expressions safely using AST-based parsing."""

    name = "calculator"
    description = "Evaluate mathematical expressions safely"
    parameters = {
        "type": "object",
        "properties": {
            "expression": {
                "type": "string",
                "description": "Mathematical expression to evaluate (supports +, -, *, /, **, %, sqrt, sin, cos, tan, log, log10, pi, e, ceil, floor)",
            },
        },
        "required": ["expression"],
    }

    async def execute(self, params: dict[str, Any]) -> dict[str, Any]:
        """Execute calculator evaluation using safe AST parser."""
        try:
            expression = params.get("expression", "")
            if not expression:
                return {"error": "Expression is required"}
            result = safe_evaluate(expression)
            return {"result": str(result), "expression": expression}
        except (ValueError, TypeError, SyntaxError, ZeroDivisionError) as e:
            logger.error("Calculator skill error: %s", str(e))
            return {"error": f"Invalid expression: {str(e)}"}
        except Exception as e:
            logger.error("Calculator skill unexpected error: %s", str(e))
            return {"error": f"Evaluation failed: {str(e)}"}
