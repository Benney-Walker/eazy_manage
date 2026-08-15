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

  const ApiException(this.message, this.kind, {this.statusCode});

  bool get isSessionExpired => kind == ApiFailureKind.unauthorized;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}

typedef OnUnauthorized = void Function();

typedef OnTokenRefreshed = void Function(String newAccessToken);

class ApiClient {
  final Dio _dio;
  final TokenStorage _storage;
  OnUnauthorized? onUnauthorized;
  OnTokenRefreshed? onTokenRefreshed;

  String? _tokenInMemory;
  String? _staffIdInMemory;
  String? _refreshTokenInMemory;

  Future<String?>? _refreshInFlight;

  void setCredentials({
    required String token,
    required String staffId,
    String? refreshToken,
  }) {
    _tokenInMemory = token;
    _staffIdInMemory = staffId;
    if (refreshToken != null) _refreshTokenInMemory = refreshToken;
  }

  void clearCredentials() {
    _tokenInMemory = null;
    _staffIdInMemory = null;
    _refreshTokenInMemory = null;
    _refreshInFlight = null;
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

  Future<List<int>> getBytes(String path,
      {Map<String, dynamic>? query, bool triggerLogoutOn401 = true}) async {
    final res = await _send(
          () => _dio.get(
        path,
        queryParameters: query,
        options: Options(responseType: ResponseType.bytes),
      ),
      triggerLogoutOn401: triggerLogoutOn401,
    );
    final data = res.data;
    if (data is List<int>) return data;
    if (data is List) return data.cast<int>();
    return const [];
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
        bool allowRefresh = true,
      }) async {
    late final Response<dynamic> res;
    try {
      res = await run();
    } on DioException catch (e) {
      // Our own interceptor rejects tokenless authenticated calls with
      // type.cancel — surface that as an auth error, but do NOT fire the
      // global logout from a read (the caller decides via triggerLogoutOn401).
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
      // The access token is short-lived (15 min). Before treating a 401 as a
      // dead session, try to mint a new access token with the refresh token
      // and replay the original request once. Only if that fails do we log out.
      if (allowRefresh) {
        final newToken = await _tryRefresh();
        if (newToken != null) {
          // Retry the original request once, with refresh disabled to avoid
          // loops if it still 401s.
          return _send(run,
              triggerLogoutOn401: triggerLogoutOn401, allowRefresh: false);
        }
      }
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

  Future<String?> _tryRefresh() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<String?> _doRefresh() async {
    final refreshToken = _refreshTokenInMemory ?? await _storage.refreshToken;
    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      // The refresh call is itself an /auth/ call, so the request interceptor
      // won't attach the (expired) access token to it.
      final res = await _dio.post(
        Endpoints.refreshToken,
        data: {'refreshToken': refreshToken},
      );
      final code = res.statusCode ?? 0;
      if (code < 200 || code >= 300) return null;

      final data = res.data;
      final newToken =
      (data is Map && data['authToken'] is String) ? data['authToken'] as String : null;
      if (newToken == null || newToken.isEmpty) return null;

      // Update in-memory + let the app persist it.
      _tokenInMemory = newToken;
      await _storage.updateAccessToken(newToken);
      onTokenRefreshed?.call(newToken);
      return newToken;
    } on DioException {
      return null;
    }
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