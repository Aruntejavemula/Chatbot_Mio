import 'package:dio/dio.dart';

import '../models/chat_model.dart';
import '../models/project_model.dart';
import 'api_service.dart';

class ProjectService extends ApiService {
  Future<List<ProjectModel>> getProjects() async {
    try {
      final response = await get<List<dynamic>>('/projects');
      final data = response.data ?? [];
      return data
          .map((json) => ProjectModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  Future<ProjectModel> createProject({
    required String name,
    required String color,
    required String systemPrompt,
  }) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/projects',
        data: {
          'name': name,
          'color': color,
          'system_prompt': systemPrompt,
        },
      );
      return ProjectModel.fromJson(response.data!);
    } on DioException {
      rethrow;
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    try {
      await patch('/projects/$id', data: data);
    } on DioException {
      rethrow;
    }
  }

  Future<void> deleteProject(String id) async {
    try {
      await delete('/projects/$id');
    } on DioException {
      rethrow;
    }
  }

  Future<List<ChatModel>> getProjectChats(String id) async {
    try {
      final response = await get<List<dynamic>>('/projects/$id/chats');
      final data = response.data ?? [];
      return data
          .map((json) => ChatModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }
}
