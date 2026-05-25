import 'package:dio/dio.dart';

import '../models/skill_model.dart';
import 'api_service.dart';

class SkillService extends ApiService {
  Future<List<SkillModel>> getSkills() async {
    try {
      final response = await get<Map<String, dynamic>>('/chat/skills');
      final data = response.data;
      if (data == null || !data.containsKey('skills')) {
        return [];
      }
      final skills = data['skills'] as List<dynamic>;
      return skills
          .map((dynamic item) => SkillModel.fromJson(item as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  List<String> getActiveSkillNames(List<SkillModel> skills) {
    return skills
        .where((SkillModel s) => s.isActive)
        .map((SkillModel s) => s.name)
        .toList();
  }
}
