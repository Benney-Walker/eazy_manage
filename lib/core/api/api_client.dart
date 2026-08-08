import 'package:dio/dio.dart';

import 'api_config.dart';
import 'token_storage.dart';

enum ApiFailureKind { network, unauthorized, forbidden, server, unknown }

class ApiException implements Exception {
  final String message;
  final ApiFailureKind kind;
  final int? statusCode;

  const ApiException(this.message, this.kind, {this.statusCode});

  bool get isSessionExpired => kind == ApiFailureKind.unauthorized;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}

typedef OnUnauthorized = void Function();

class ApiClient {
  final Dio _dio;
  final TokenStorage _storage;
  OnUnauthorized? onUnauthorized;

  ApiClient({required TokenStorage storage, Dio? dio})
      : _storage = storage,
        _dio = dio ??
            Dio(BaseOptions(
              baseUrl: ApiConfig.LOCAL_URL,
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
            final token = await _storage.token;
            final staffId = await _storage.staffId;
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
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

  Future<Response<dynamic>> get(String path, {Map<String, dynamic>? query}) {
    return _send(() => _dio.get(path, queryParameters: query));
  }

  Future<Response<dynamic>> post(String path, {Object? body}) {
    return _send(() => _dio.post(path, data: body));
  }

  Future<Response<dynamic>> put(String path, {Object? body}) {
    return _send(() => _dio.put(path, data: body));
  }

  Future<Response<dynamic>> delete(String path, {Object? body}) {
    return _send(() => _dio.delete(path, data: body));
  }

  // -------------------------------------------------------------------------

  Future<Response<dynamic>> _send(Future<Response<dynamic>> Function() run) async {
    late final Response<dynamic> res;
    try {
      res = await run();
    } on DioException catch (e) {
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
      onUnauthorized?.call();
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
