import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  String? _selectedProvider;

  String? get selectedProvider => _selectedProvider;

  Future<void> initialize(String plan, String? provider) async {
    try {
      if (plan == 'free') {
        _selectedProvider = null;
      } else if (plan == 'basic') {
        _selectedProvider = provider;
      } else if (plan == 'pro') {
        _selectedProvider = 'supabase';
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveChat(
    String chatId,
    Map<String, Object?> data,
    String provider,
  ) async {
    try {
      switch (provider) {
        case 'google_drive':
          await saveToDrive(chatId, data);
        case 'icloud':
          await saveToICloud(chatId, data);
        case 'onedrive':
          await saveToOneDrive(chatId, data);
        default:
          await saveLocally(chatId, data);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, Object?>?> loadChat(
    String chatId,
    String provider,
  ) async {
    try {
      switch (provider) {
        case 'google_drive':
          return await loadFromDrive(chatId);
        case 'icloud':
          return await loadFromICloud(chatId);
        case 'onedrive':
          return await loadFromOneDrive(chatId);
        default:
          return await loadLocally(chatId);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> saveToDrive(String chatId, Map<String, Object?> data) async {
    // Requires googleapis package - saves to hidden app folder
    // File name: mio_chat_{chatId}.json
  }

  Future<void> saveToICloud(String chatId, Map<String, Object?> data) async {
    // Requires icloud_storage package
    // Saves to iCloud Documents: mio_chat_{chatId}.json
  }

  Future<void> saveToOneDrive(String chatId, Map<String, Object?> data) async {
    // Requires Microsoft Graph API
    // PUT /me/drive/appRoot:/MioChats/{chatId}.json
  }

  Future<void> saveLocally(String chatId, Map<String, Object?> data) async {
    try {
      final jsonString = jsonEncode(data);
      await _secureStorage.write(key: 'chat_$chatId', value: jsonString);
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, Object?>?> loadFromDrive(String chatId) async {
    return null;
  }

  Future<Map<String, Object?>?> loadFromICloud(String chatId) async {
    return null;
  }

  Future<Map<String, Object?>?> loadFromOneDrive(String chatId) async {
    return null;
  }

  Future<Map<String, Object?>?> loadLocally(String chatId) async {
    try {
      final jsonString = await _secureStorage.read(key: 'chat_$chatId');
      if (jsonString == null) return null;
      final decoded = jsonDecode(jsonString);
      if (decoded is Map<String, Object?>) return decoded;
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
