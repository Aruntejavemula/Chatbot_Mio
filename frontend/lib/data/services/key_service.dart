import 'package:dio/dio.dart';

import '../models/api_key_model.dart';
import 'api_service.dart';

class KeyService extends ApiService {
  Future<List<ApiKeyModel>> getApiKeys() async {
    try {
      final response = await get<List<dynamic>>('/keys');
      final data = response.data ?? [];
      return data
          .map((json) => ApiKeyModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<void> saveApiKey(String provider, String rawKey) async {
    try {
      await post(
        '/keys',
        data: {'provider': provider, 'key': rawKey},
      );
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteApiKey(String provider) async {
    try {
      await delete('/keys/$provider');
    } on DioException {
      rethrow;
    }
  }

  Future<bool> testApiKey(String provider, String rawKey) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/keys/test',
        data: {'provider': provider, 'key': rawKey},
      );
      return response.data?['valid'] == true;
    } on DioException {
      rethrow;
    }
  }
}
