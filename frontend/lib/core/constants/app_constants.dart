class AppConstants {
  AppConstants._();

  // Pricing
  static const double basicMonthlyPrice = 4.99;
  static const double basicAnnualPrice = 49.99;
  static const double proMonthlyPrice = 9.99;
  static const double proAnnualPrice = 99.99;
  static const int annualSavingsPercent = 17;

  // Token Caps
  static const int freeTokenCap5Hour = 40000;
  static const int basicTokenCapDaily = 100000;
  static const int proTokenCapWeekly = 500000;
  static const int proTokenCapMonthly = 2000000;

  // Token Cap Display Names
  static const String freeTokenCapDisplay = '40K';
  static const String basicTokenCapDisplay = '100K';
  static const String proTokenCapDisplay = '500K';
  static const String proMonthlyCapDisplay = '2M';

  // Device Limits
  static const int freeDeviceLimit = 1;
  static const int basicDeviceLimit = 3;
  static const int proDeviceLimit = 10;

  // Trial
  static const int trialDurationDays = 14;

  // File Limits
  static const int maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  // UI
  static const int usageRefreshIntervalSeconds = 60;

  // Cost Protection
  static const int defaultDailyTokenLimit = 100000;

  // Display helpers
  static String get fiveHourCapDisplay => '5-hour ($freeTokenCapDisplay)';
  static String get dailyCapDisplay => 'Daily ($basicTokenCapDisplay)';
  static String get weeklyCapDisplay => 'Weekly ($proTokenCapDisplay)';
  static String get monthlyCapDisplay => 'Monthly ($proMonthlyCapDisplay)';
}
