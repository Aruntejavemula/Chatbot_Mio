import 'package:dio/dio.dart';

import '../models/referral_model.dart';
import 'api_service.dart';

class ReferralService extends ApiService {
  Future<String> getMyCode() async {
    try {
      final response = await get<Map<String, dynamic>>('/referral/code');
      final data = response.data ?? {};
      return data['code'] as String? ?? '';
    } on DioException {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> applyCode(String code) async {
    try {
      final response = await post<Map<String, dynamic>>(
        '/referral/apply',
        data: {'code': code},
      );
      return response.data ?? {};
    } on DioException {
      rethrow;
    }
  }

  Future<ReferralModel> getStats() async {
    try {
      final response = await get<Map<String, dynamic>>('/referral/stats');
      return ReferralModel.fromJson(response.data ?? {});
    } on DioException {
      rethrow;
    }
  }
}
