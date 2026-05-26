import 'package:dio/dio.dart';

import '../models/memory_model.dart';
import 'api_service.dart';

class MemoryService extends ApiService {
  Future<List<MemoryModel>> getMemories() async {
    try {
      final response = await get<Map<String, dynamic>>('/memory');
      final data = response.data;
      if (data == null || !data.containsKey('memories')) return [];
      final memories = data['memories'] as List<dynamic>;
      return memories
          .map((dynamic item) => MemoryModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<void> addMemory(String content, {int importance = 5}) async {
    try {
      await post('/memory', data: {'content': content, 'importance': importance});
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteMemory(String id) async {
    try {
      await delete('/memory/$id');
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteAllMemories() async {
    try {
      await dio.delete(
        '/memory/all',
        options: Options(headers: {'X-Confirm-Delete': 'true'}),
      );
    } on DioException {
      rethrow;
    }
  }
}
