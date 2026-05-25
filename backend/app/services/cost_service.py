"""Cost calculation service for token usage billing."""


class CostService:
    """Service for calculating and formatting token costs."""

    RATES = {
        'deepseek-chat': {'input': 0.00000027, 'output': 0.0000011},
        'deepseek-reasoner': {'input': 0.00000055, 'output': 0.0000022},
        'claude-sonnet-4-5': {'input': 0.000003, 'output': 0.000015},
        'claude-haiku-4-5': {'input': 0.00000025, 'output': 0.00000125},
        'gpt-4o': {'input': 0.0000025, 'output': 0.00001},
        'gpt-4o-mini': {'input': 0.00000015, 'output': 0.0000006},
        'gemini-2.5-pro': {'input': 0.00000125, 'output': 0.00001},
        'gemini-2.5-flash': {'input': 0.000000075, 'output': 0.0000003},
    }

    DEFAULT_RATE = {'input': 0.000001, 'output': 0.000002}

    def calculate_cost(self, model: str, input_tokens: int, output_tokens: int) -> float:
        """Calculate the cost for a given model and token counts."""
        rates = self.RATES.get(model, self.DEFAULT_RATE)
        return input_tokens * rates['input'] + output_tokens * rates['output']

    def format_cost(self, cost: float) -> str:
        """Format a cost value as a string."""
        if cost < 0.001:
            return '<$0.001'
        return f'${cost:.3f}'
