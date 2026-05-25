import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

class AuthService extends ApiService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';

  Future<Map<String, dynamic>> googleSignIn(String idToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/google',
        data: {'id_token': idToken},
      );
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> appleSignIn(String identityToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/apple',
        data: {'identity_token': identityToken},
      );
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> microsoftSignIn(String idToken) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/auth/microsoft',
        data: {'identity_token': idToken},
      );
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await post('/auth/signout');
      await clearToken();
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await get<Map<String, dynamic>>('/auth/profile');
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<void> saveTokenSecurely(String token) async {
    await _secureStorage.write(key: _tokenKey, value: token);
  }

  Future<String?> getStoredToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  Future<void> clearToken() async {
    await _secureStorage.delete(key: _tokenKey);
  }
}
