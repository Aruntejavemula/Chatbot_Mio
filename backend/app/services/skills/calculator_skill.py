"""Calculator skill for evaluating safe math expressions."""
import ast
import operator


class CalculatorSkill:
    """Evaluates safe mathematical expressions."""

    OPERATORS = {
        ast.Add: operator.add,
        ast.Sub: operator.sub,
        ast.Mult: operator.mul,
        ast.Div: operator.truediv,
        ast.Pow: operator.pow,
        ast.USub: operator.neg,
    }

    def evaluate(self, expression: str) -> float:
        """Safely evaluate a mathematical expression."""
        try:
            tree = ast.parse(expression, mode='eval')
            return self._eval_node(tree.body)
        except (ValueError, TypeError, ZeroDivisionError, SyntaxError) as e:
            raise ValueError(f"Invalid expression: {expression}") from e

    def _eval_node(self, node: ast.AST) -> float:
        if isinstance(node, ast.Constant) and isinstance(node.value, (int, float)):
            return float(node.value)
        elif isinstance(node, ast.BinOp):
            left = self._eval_node(node.left)
            right = self._eval_node(node.right)
            op_func = self.OPERATORS.get(type(node.op))
            if op_func is None:
                raise ValueError(f"Unsupported operator: {type(node.op).__name__}")
            return op_func(left, right)
        elif isinstance(node, ast.UnaryOp):
            operand = self._eval_node(node.operand)
            op_func = self.OPERATORS.get(type(node.op))
            if op_func is None:
                raise ValueError(f"Unsupported unary operator: {type(node.op).__name__}")
            return op_func(operand)
        else:
            raise ValueError(f"Unsupported expression type: {type(node).__name__}")
