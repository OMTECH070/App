import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:8000';  // Change for production

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      contentType: Headers.jsonContentType,
    ),
  );

  String? _accessToken;
  String? _refreshToken;

  ApiService() {
    // Add logging interceptor in debug mode
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_accessToken != null) {
            options.headers['Authorization'] = 'Bearer $_accessToken';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 && _refreshToken != null) {
            // Try to refresh token
            try {
              final response = await refreshTokenRequest();
              _accessToken = response['access_token'];
              _refreshToken = response['refresh_token'];

              // Retry original request
              final options = error.requestOptions;
              options.headers['Authorization'] = 'Bearer $_accessToken';
              return handler.resolve(await _dio.request(
                options.path,
                options: Options(
                  method: options.method,
                  headers: options.headers,
                  contentType: options.contentType,
                ),
                data: options.data,
                queryParameters: options.queryParameters,
              ));
            } catch (e) {
              return handler.next(error);
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // Setters for tokens
  void setTokens(String? accessToken, String? refreshToken) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  // Auth Endpoints
  Future<Map<String, dynamic>> register({
    required String email,
    required String phone,
    required String password,
    required String name,
    required String language,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'phone': phone,
        'password': password,
        'name': name,
        'language': language,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> refreshTokenRequest() async {
    try {
      final response = await _dio.post('/auth/refresh', data: {
        'refresh_token': _refreshToken,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout({required String refreshToken}) async {
    try {
      await _dio.post('/auth/logout', data: {
        'refresh_token': refreshToken,
      });
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Device Endpoints
  Future<Map<String, dynamic>> getDevices() async {
    try {
      final response = await _dio.get('/devices/');
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> pairDevice({
    required String deviceId,
    required String fieldName,
  }) async {
    try {
      final response = await _dio.post('/devices/pair', data: {
        'device_id': deviceId,
        'field_name': fieldName,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getDeviceStatus(String deviceId) async {
    try {
      final response = await _dio.get('/devices/$deviceId/status');
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteDevice(String deviceId) async {
    try {
      await _dio.delete('/devices/$deviceId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Sensor Endpoints
  Future<Map<String, dynamic>> getLatestSensorReading(String deviceId) async {
    try {
      final response = await _dio.get('/sensors/$deviceId/latest');
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getSensorHistory({
    required String deviceId,
    required int hours,
  }) async {
    try {
      final response = await _dio.get(
        '/sensors/$deviceId/history',
        queryParameters: {'hours': hours},
      );

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Irrigation Endpoints
  Future<Map<String, dynamic>> startIrrigation({
    required String deviceId,
    required int durationMinutes,
    String mode = 'manual',
  }) async {
    try {
      final response = await _dio.post('/irrigation/start', data: {
        'device_id': deviceId,
        'duration_minutes': durationMinutes,
        'mode': mode,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> stopIrrigation(String deviceId) async {
    try {
      final response = await _dio.post('/irrigation/stop', data: {
        'device_id': deviceId,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Notification Endpoints
  Future<Map<String, dynamic>> getNotifications({
    int limit = 50,
    int offset = 0,
    String type = 'all',
  }) async {
    try {
      final response = await _dio.get('/notifications/', queryParameters: {
        'limit': limit,
        'offset': offset,
        'type': type,
      });

      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await _dio.delete('/notifications/$notificationId');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Settings Endpoints
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final response = await _dio.get('/settings/');
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> updateSettings({
    String? language,
    String? timezone,
    bool? notificationSoundsEnabled,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (language != null) data['language'] = language;
      if (timezone != null) data['timezone'] = timezone;
      if (notificationSoundsEnabled != null) {
        data['notification_sounds_enabled'] = notificationSoundsEnabled;
      }

      final response = await _dio.patch('/settings/', data: data);
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // AI Endpoints
  Future<Map<String, dynamic>> getAIRecommendation(String deviceId) async {
    try {
      final response = await _dio.get('/ai/recommendation/$deviceId');
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> applyAIRecommendation(String deviceId) async {
    try {
      final response = await _dio.post('/ai/recommendation/$deviceId/apply');
      return Map<String, dynamic>.from(response.data ?? {});
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Error handling
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.sendTimeout:
        return 'Request timeout. Please try again.';
      case DioExceptionType.receiveTimeout:
        return 'Response timeout. Please try again.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final message = error.response?.data?['detail'] ??
            error.response?.data?['message'] ??
            'Error occurred';
        return 'Error: $message (Code: $statusCode)';
      case DioExceptionType.badCertificate:
        return 'SSL Certificate error. Please contact support.';
      case DioExceptionType.connectionError:
        return 'Connection error. Please check your internet connection.';
      case DioExceptionType.unknown:
        return error.message ?? 'An unknown error occurred.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
