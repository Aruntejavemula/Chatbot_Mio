import 'package:flutter_test/flutter_test.dart';
import 'package:mio/core/constants/cost_rates.dart';

void main() {
  group('CostRates', () {
    group('calculateCost', () {
      test('calculates cost for known model gpt-4o', () {
        // gpt-4o: input=0.0000025, output=0.00001
        final cost = CostRates.calculateCost('gpt-4o', 1000, 500);
        // 1000 * 0.0000025 + 500 * 0.00001 = 0.0025 + 0.005 = 0.0075
        expect(cost, closeTo(0.0075, 0.0000001));
      });

      test('calculates cost for known model deepseek-chat', () {
        // deepseek-chat: input=0.00000027, output=0.0000011
        final cost = CostRates.calculateCost('deepseek-chat', 10000, 5000);
        // 10000 * 0.00000027 + 5000 * 0.0000011 = 0.0027 + 0.0055 = 0.0082
        expect(cost, closeTo(0.0082, 0.0000001));
      });

      test('uses default rate for unknown model', () {
        // defaultRate: input=0.000001, output=0.000002
        final cost = CostRates.calculateCost('unknown-model', 1000, 1000);
        // 1000 * 0.000001 + 1000 * 0.000002 = 0.001 + 0.002 = 0.003
        expect(cost, closeTo(0.003, 0.0000001));
      });

      test('returns zero for zero tokens', () {
        final cost = CostRates.calculateCost('gpt-4o', 0, 0);
        expect(cost, 0.0);
      });
    });

    group('formatCost', () {
      test('returns formatted string for cost >= 0.001', () {
        expect(CostRates.formatCost(0.005), '\$0.005');
        expect(CostRates.formatCost(1.234), '\$1.234');
        expect(CostRates.formatCost(0.001), '\$0.001');
      });

      test('returns "<\$0.001" for cost < 0.001', () {
        expect(CostRates.formatCost(0.0009), '<\$0.001');
        expect(CostRates.formatCost(0.0001), '<\$0.001');
        expect(CostRates.formatCost(0.0), '<\$0.001');
      });
    });

    group('rates map', () {
      test('contains expected models', () {
        expect(CostRates.rates.containsKey('gpt-4o'), true);
        expect(CostRates.rates.containsKey('gpt-4o-mini'), true);
        expect(CostRates.rates.containsKey('claude-sonnet-4-5'), true);
        expect(CostRates.rates.containsKey('deepseek-chat'), true);
        expect(CostRates.rates.containsKey('gemini-2.5-pro'), true);
      });
    });
  });
}
