import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

enum ApiFailureKind {
  network,
  unauthorized,
  forbidden,
  server,
  unknown
}

class ApiException implements Exception {
  final String message;
  final ApiFailureKind kind;
  final int? statusCode;

  const ApiException(
      this.message,
      this.kind,
      {this.statusCode}
      );

  bool get isSessionExpired => kind == ApiFailureKind.unauthorized;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}

typedef OnUnauthorized = void Function();

class ApiClient {
  final Dio _dio;
  final TokenStorage _storage;
  OnUnauthorized? onUnauthorized;

  String? _tokenInMemory;
  String? _staffIdInMemory;

  void setCredentials({required String token, required String staffId}) {
    _tokenInMemory = token;
    _staffIdInMemory = staffId;
  }

  void clearCredentials() {
    _tokenInMemory = null;
    _staffIdInMemory = null;
  }

  ApiClient({required TokenStorage storage, Dio? dio})
      : _storage = storage,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.BASE_URL,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              // We validate status ourselves so we can map errors cleanly.
              validateStatus: (_) => true,
            )) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Login is the one call that must NOT carry a stale token/staffId.
          final isAuthCall = options.path.contains('${ApiConfig.auth}/');
          if (!isAuthCall) {

            final token = _tokenInMemory ?? await _storage.token;
            final staffId = _staffIdInMemory ?? await _storage.staffId;

            if (token == null || token.isEmpty) {

              return handler.reject(
                DioException(
                  requestOptions: options,
                  type: DioExceptionType.cancel,
                  error: 'No auth token available for ${options.path}',
                ),
                true,
              );
            }

            options.headers['Authorization'] = 'Bearer $token';
            if (staffId != null && staffId.isNotEmpty) {
              options.headers['staffId'] = staffId;
            }
          }
          handler.next(options);
        },
      ),
    );
  }

  Dio get raw => _dio;

  // ---- Verb helpers that return the decoded body or throw ApiException -----

  Future<Response<dynamic>> get(String path,
      {Map<String, dynamic>? query, bool triggerLogoutOn401 = true}) {
    return _send(() => _dio.get(path, queryParameters: query),
        triggerLogoutOn401: triggerLogoutOn401);
  }

  Future<Response<dynamic>> post(String path,
      {Object? body, bool triggerLogoutOn401 = true}) {
    return _send(() => _dio.post(path, data: body),
        triggerLogoutOn401: triggerLogoutOn401);
  }

  Future<Response<dynamic>> put(String path,
      {Object? body, bool triggerLogoutOn401 = true}) {
    return _send(() => _dio.put(path, data: body),
        triggerLogoutOn401: triggerLogoutOn401);
  }

  Future<Response<dynamic>> delete(String path,
      {Object? body, bool triggerLogoutOn401 = true}) {
    return _send(() => _dio.delete(path, data: body),
        triggerLogoutOn401: triggerLogoutOn401);
  }

  // -------------------------------------------------------------------------

  Future<Response<dynamic>> _send(
      Future<Response<dynamic>> Function() run, {
        bool triggerLogoutOn401 = true,
      }) async {
    late final Response<dynamic> res;
    try {
      res = await run();
    } on DioException catch (e) {

      if (e.type == DioExceptionType.cancel) {
        throw const ApiException(
          'Not authenticated. Please sign in again.',
          ApiFailureKind.unauthorized,
        );
      }
      // Transport-level failures (no connection, timeout, DNS, etc.)
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        throw const ApiException(
          'Cannot reach the server. Check your connection and try again.',
          ApiFailureKind.network,
        );
      }
      throw ApiException(
        e.message ?? 'Unexpected network error.',
        ApiFailureKind.unknown,
      );
    }

    final code = res.statusCode ?? 0;
    if (code >= 200 && code < 300) return res;

    // Map non-2xx to a typed exception, pulling the backend message if present.
    final message = _extractMessage(res.data) ?? _defaultMessageFor(code);

    if (code == 401) {
      if (triggerLogoutOn401) onUnauthorized?.call();
      throw ApiException(message, ApiFailureKind.unauthorized, statusCode: code);
    }
    if (code == 403) {
      throw ApiException(message, ApiFailureKind.forbidden, statusCode: code);
    }
    if (code >= 500) {
      throw ApiException(message, ApiFailureKind.server, statusCode: code);
    }
    throw ApiException(message, ApiFailureKind.unknown, statusCode: code);
  }

  /// Backend error bodies look like `{"message": "...", "status": 401, ...}`.
  String? _extractMessage(dynamic data) {
    if (data is Map && data['message'] is String) {
      final m = data['message'] as String;
      if (m.trim().isNotEmpty) return m;
    }
    return null;
  }

  String _defaultMessageFor(int code) {
    return switch (code) {
      401 => 'Your session has expired. Please sign in again.',
      403 => 'You don\'t have permission to do that.',
      404 => 'Not found.',
      >= 500 => 'Something went wrong on the server. Contact your developer.',
      _ => 'Request failed ($code).',
    };
  }
}