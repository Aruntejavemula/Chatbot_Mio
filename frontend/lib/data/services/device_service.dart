import 'dart:io';

import 'package:crypto/crypto.dart';
import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../models/device_model.dart';
import 'api_service.dart';

class DeviceService extends ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  static const String _deviceIdKey = 'device_id';

  Future<String> getDeviceId() async {
    final cached = await _secureStorage.read(key: _deviceIdKey);
    if (cached != null) return cached;

    final packageInfo = await PackageInfo.fromPlatform();
    String rawIdentifier;

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      rawIdentifier =
          '${androidInfo.id}-${androidInfo.model}-${packageInfo.packageName}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      rawIdentifier =
          '${iosInfo.identifierForVendor ?? ''}-${iosInfo.model}-${packageInfo.packageName}';
    } else {
      rawIdentifier = '${Platform.operatingSystem}-${packageInfo.packageName}';
    }

    final deviceId =
        sha256.convert(utf8.encode(rawIdentifier)).toString();

    await _secureStorage.write(key: _deviceIdKey, value: deviceId);
    return deviceId;
  }

  Future<void> registerDevice() async {
    try {
      final deviceId = await getDeviceId();
      String deviceName;
      String deviceType;

      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceName = '${androidInfo.brand} ${androidInfo.model}';
        deviceType = 'android';
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceName = iosInfo.name;
        deviceType = 'ios';
      } else {
        deviceName = Platform.localHostname;
        deviceType = Platform.operatingSystem;
      }

      await post(
        '/devices/register',
        data: {
          'device_id': deviceId,
          'device_name': deviceName,
          'device_type': deviceType,
        },
      );
    } on DioException {
      rethrow;
    }
  }

  Future<List<DeviceModel>> getDevices() async {
    try {
      final response = await get<List<dynamic>>('/devices');
      final data = response.data ?? [];
      return data
          .map((json) => DeviceModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<void> removeDevice(String deviceId) async {
    try {
      await delete('/devices/$deviceId');
    } on DioException {
      rethrow;
    }
  }
}
