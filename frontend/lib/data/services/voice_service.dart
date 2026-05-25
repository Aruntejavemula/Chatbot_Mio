import 'package:dio/dio.dart';

class VoiceService {
  final Dio _dio;

  static const String _baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  VoiceService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: _baseUrl,
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
          ),
        );

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
