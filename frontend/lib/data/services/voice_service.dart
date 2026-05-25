import 'package:dio/dio.dart';

import 'api_service.dart';

class VoiceService {
  final Dio _dio;

  /// Creates a VoiceService that uses the ApiService's Dio instance,
  /// which includes the JWT auth interceptor for authenticated requests.
  VoiceService(ApiService apiService) : _dio = apiService.dio;

  Future<String> transcribeAudio(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: 'recording.m4a',
        ),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/voice/transcribe',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

      final data = response.data;
      if (data == null || !data.containsKey('transcript')) {
        throw DioException(
          requestOptions: response.requestOptions,
          error: 'Invalid response: missing transcript field',
        );
      }

      return data['transcript'] as String;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: '/voice/transcribe'),
        error: 'Transcription failed: ${e.toString()}',
      );
    }
  }
}
