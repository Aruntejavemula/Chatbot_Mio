import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  late final Dio dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _tokenKey = 'jwt_token';

  ApiService() {
    dio = Dio(
      BaseOptions(
        baseUrl: const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'http://127.0.0.1:8000',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: _onRequest,
        onError: _onError,
      ),
    );
  }

  Future<void> _onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _secureStorage.read(key: _tokenKey);
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  Future<void> _onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) async {
    switch (error.response?.statusCode) {
      case 401:
        await _secureStorage.delete(key: _tokenKey);
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: 'Session expired. Please sign in again.',
            type: DioExceptionType.badResponse,
            response: error.response,
          ),
        );
        return;
      case 429:
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: 'Too many requests. Please wait a moment and try again.',
            type: DioExceptionType.badResponse,
            response: error.response,
          ),
        );
        return;
      case 500:
        handler.reject(
          DioException(
            requestOptions: error.requestOptions,
            error: 'Server error. Please try again later.',
            type: DioExceptionType.badResponse,
            response: error.response,
          ),
        );
        return;
    }
    handler.next(error);
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.get<T>(
        path,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e.toString(),
      );
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e.toString(),
      );
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e.toString(),
      );
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
      );
      return response;
    } on DioException {
      rethrow;
    } catch (e) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        error: e.toString(),
      );
    }
  }
}
