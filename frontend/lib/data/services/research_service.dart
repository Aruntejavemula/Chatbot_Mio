import 'dart:async';

import 'package:dio/dio.dart';

import 'api_service.dart';

class ResearchService extends ApiService {
  Future<String> startResearch(String query, String model) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/chat/deep-research',
        data: {'query': query, 'chat_id': '', 'num_searches': 3},
      );
      final data = response.data;
      if (data == null || !data.containsKey('task_id')) {
        throw DioException(
          requestOptions: RequestOptions(path: '/chat/deep-research'),
          error: 'No task_id returned',
        );
      }
      return data['task_id'] as String;
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> checkStatus(String taskId) async {
    try {
      final response = await get<Map<String, dynamic>>('/chat/task/$taskId');
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<String> pollUntilDone(
    String taskId, {
    Duration interval = const Duration(seconds: 3),
    int maxAttempts = 60,
  }) async {
    for (int i = 0; i < maxAttempts; i++) {
      final status = await checkStatus(taskId);
      final state = status['status'] as String? ?? 'pending';
      if (state == 'done') {
        final result = status['result'];
        if (result is Map) return result['result'] as String? ?? '';
        if (result is String) return result;
        return '';
      }
      if (state == 'failed') {
        throw DioException(
          requestOptions: RequestOptions(path: '/chat/task/$taskId'),
          error: status['error'] as String? ?? 'Research failed',
        );
      }
      await Future<void>.delayed(interval);
    }
    throw DioException(
      requestOptions: RequestOptions(path: '/chat/task/$taskId'),
      error: 'Research timed out after ${maxAttempts * interval.inSeconds} seconds',
    );
  }
}
