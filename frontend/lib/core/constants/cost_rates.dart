class CostRates {
  CostRates._();

  static const Map<String, Map<String, double>> rates = {
    'deepseek-chat': {'input': 0.00000027, 'output': 0.0000011},
    'deepseek-reasoner': {'input': 0.00000055, 'output': 0.0000022},
    'claude-sonnet-4-5': {'input': 0.000003, 'output': 0.000015},
    'claude-haiku-4-5': {'input': 0.00000025, 'output': 0.00000125},
    'gpt-4o': {'input': 0.0000025, 'output': 0.00001},
    'gpt-4o-mini': {'input': 0.00000015, 'output': 0.0000006},
    'gemini-2.5-pro': {'input': 0.00000125, 'output': 0.00001},
    'gemini-2.5-flash': {'input': 0.000000075, 'output': 0.0000003},
  };

  static const Map<String, double> defaultRate = {
    'input': 0.000001,
    'output': 0.000002,
  };

  static double calculateCost(String model, int inputTokens, int outputTokens) {
    final modelRates = rates[model] ?? defaultRate;
    return inputTokens * (modelRates['input'] ?? 0) +
        outputTokens * (modelRates['output'] ?? 0);
  }

  static String formatCost(double cost) {
    if (cost < 0.001) return '<\$0.001';
    return '\$${cost.toStringAsFixed(3)}';
  }
}
