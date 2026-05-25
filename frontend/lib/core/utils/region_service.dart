import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RegionService {
  RegionService._();

  static const String _key = 'user_region';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  /// Middle tier countries list
  static const List<String> _middleTierCountries = [
    'BR', 'MX', 'PL', 'AR', 'CO', 'CL', 'PE', 'ZA', 'NG', 'EG',
    'PK', 'BD', 'VN', 'PH', 'ID', 'TH', 'MY', 'UA', 'RO', 'HU',
  ];

  /// Get user's region (cached in FlutterSecureStorage)
  static Future<String> getRegion() async {
    // Check cache first
    final cached = await _storage.read(key: _key);
    if (cached != null) return cached;

    // Detect from device locale
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final country = locale.countryCode ?? 'US';

    // Cache it
    await _storage.write(key: _key, value: country);
    return country;
  }

  static bool isIndian(String country) => country == 'IN';

  static bool isMiddleTier(String country) =>
      _middleTierCountries.contains(country);

  static bool isPremium(String country) =>
      !isIndian(country) && !isMiddleTier(country);

  /// Get formatted price display string
  static String getPriceDisplay(String country, String plan, bool isAnnual) {
    if (isIndian(country)) {
      if (plan == 'basic') {
        return isAnnual ? '\u20B9999/yr' : '\u20B999/mo';
      } else {
        return isAnnual ? '\u20B92,999/yr' : '\u20B9299/mo';
      }
    } else if (isMiddleTier(country)) {
      if (plan == 'basic') {
        return '\$2.99/mo';
      } else {
        return '\$5.99/mo';
      }
    } else {
      // Premium
      if (plan == 'basic') {
        return isAnnual ? '\$49.99/yr' : '\$4.99/mo';
      } else {
        return isAnnual ? '\$99.99/yr' : '\$9.99/mo';
      }
    }
  }

  /// Get payment provider for region
  static String getPaymentProvider(String country) {
    return isIndian(country) ? 'razorpay' : 'stripe';
  }

  /// Whether annual billing option is available
  static bool hasAnnualOption(String country) {
    return !isMiddleTier(country);
  }
}
