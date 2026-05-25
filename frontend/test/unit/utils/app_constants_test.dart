import 'package:flutter_test/flutter_test.dart';
import 'package:mio/core/constants/app_constants.dart';

void main() {
  group('AppConstants', () {
    test('pricing constants have correct values', () {
      expect(AppConstants.basicMonthlyPrice, 4.99);
      expect(AppConstants.basicAnnualPrice, 49.99);
      expect(AppConstants.proMonthlyPrice, 9.99);
      expect(AppConstants.proAnnualPrice, 99.99);
      expect(AppConstants.annualSavingsPercent, 17);
    });

    test('token cap constants have correct values', () {
      expect(AppConstants.freeTokenCap5Hour, 40000);
      expect(AppConstants.basicTokenCapDaily, 100000);
      expect(AppConstants.proTokenCapWeekly, 500000);
      expect(AppConstants.proTokenCapMonthly, 2000000);
    });

    test('trial duration is 14 days', () {
      expect(AppConstants.trialDurationDays, 14);
    });

    test('file size limit is 10MB', () {
      expect(AppConstants.maxFileSizeBytes, 10 * 1024 * 1024);
    });

    test('agent max steps is 10', () {
      expect(AppConstants.agentMaxSteps, 10);
    });

    test('device limits are set correctly', () {
      expect(AppConstants.freeDeviceLimit, 1);
      expect(AppConstants.basicDeviceLimit, 3);
      expect(AppConstants.proDeviceLimit, 10);
    });

    test('display helpers return expected strings', () {
      expect(AppConstants.fiveHourCapDisplay, '5-hour (40K)');
      expect(AppConstants.dailyCapDisplay, 'Daily (100K)');
      expect(AppConstants.weeklyCapDisplay, 'Weekly (500K)');
      expect(AppConstants.monthlyCapDisplay, 'Monthly (2M)');
    });
  });
}
