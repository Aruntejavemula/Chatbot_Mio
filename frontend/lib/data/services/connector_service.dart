import 'package:dio/dio.dart';

import '../models/connector_model.dart';
import 'api_service.dart';

class ConnectorService extends ApiService {
  Future<List<ConnectorModel>> getConnectors() async {
    try {
      final response = await get<Map<String, dynamic>>('/connectors');
      final data = response.data;
      if (data == null || !data.containsKey('connectors')) {
        return [];
      }
      final connectors = data['connectors'] as List<dynamic>;
      return connectors
          .map((dynamic item) => ConnectorModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<String> getAuthUrl(String name) async {
    try {
      final response = await get<Map<String, dynamic>>('/connectors/$name/auth-url');
      final data = response.data;
      if (data == null || !data.containsKey('auth_url')) {
        throw DioException(
          requestOptions: RequestOptions(path: '/connectors/$name/auth-url'),
          error: 'No auth URL returned',
        );
      }
      return data['auth_url'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<void> disconnect(String name) async {
    try {
      await delete('/connectors/$name');
    } on DioException {
      rethrow;
    }
  }
}
