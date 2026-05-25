import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/api_key_model.dart';
import '../models/device_model.dart';
import '../models/subscription_model.dart';
import '../services/device_service.dart';
import '../services/key_service.dart';
import '../services/payment_service.dart';

final keyServiceProvider = Provider<KeyService>((ref) {
  return KeyService();
});

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService();
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref);
});

final themeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system;
});

class SettingsRepository {
  final Ref _ref;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _themeKey = 'app_theme';

  SettingsRepository(this._ref);

  KeyService get _keyService => _ref.read(keyServiceProvider);
  DeviceService get _deviceService => _ref.read(deviceServiceProvider);
  PaymentService get _paymentService => _ref.read(paymentServiceProvider);

  Future<void> saveTheme(ThemeMode theme) async {
    try {
      await _secureStorage.write(key: _themeKey, value: theme.name);
      _ref.read(themeProvider.notifier).state = theme;
    } catch (e) {
      rethrow;
    }
  }

  Future<ThemeMode> loadTheme() async {
    try {
      final value = await _secureStorage.read(key: _themeKey);
      final ThemeMode theme;
      switch (value) {
        case 'light':
          theme = ThemeMode.light;
        case 'dark':
          theme = ThemeMode.dark;
        default:
          theme = ThemeMode.system;
      }
      _ref.read(themeProvider.notifier).state = theme;
      return theme;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ApiKeyModel>> getApiKeys() async {
    try {
      final keys = await _keyService.getApiKeys();
      return keys;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveApiKey(String provider, String rawKey) async {
    try {
      await _keyService.saveApiKey(provider, rawKey);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteApiKey(String provider) async {
    try {
      await _keyService.deleteApiKey(provider);
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> testApiKey(String provider, String rawKey) async {
    try {
      final result = await _keyService.testApiKey(provider, rawKey);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<DeviceModel>> getDevices() async {
    try {
      final devices = await _deviceService.getDevices();
      return devices;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      await _deviceService.removeDevice(deviceId);
    } catch (e) {
      rethrow;
    }
  }

  Future<SubscriptionModel> getSubscription() async {
    try {
      final subscription = await _paymentService.getSubscriptionStatus();
      return subscription;
    } catch (e) {
      rethrow;
    }
  }
}
