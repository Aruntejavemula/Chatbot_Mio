import 'package:dio/dio.dart';

import '../models/scheduled_task_model.dart';
import 'api_service.dart';

class ScheduledService extends ApiService {
  Future<List<ScheduledTaskModel>> getTasks() async {
    try {
      final response = await get<List<dynamic>>('/scheduled-tasks');
      final data = response.data ?? [];
      return data
          .map((json) =>
              ScheduledTaskModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<ScheduledTaskModel> createTask(Map<String, dynamic> data) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/scheduled-tasks',
        data: data,
      );
      return ScheduledTaskModel.fromJson(response.data!);
    } on DioException {
      rethrow;
    }
  }

  Future<ScheduledTaskModel> updateTask(
      String id, Map<String, dynamic> data) async {
    try {
      final response = await patch<Map<String, dynamic>>(
        '/scheduled-tasks/$id',
        data: data,
      );
      return ScheduledTaskModel.fromJson(response.data!);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await delete('/scheduled-tasks/$id');
    } on DioException {
      rethrow;
    }
  }
}
