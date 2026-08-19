import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/api/token_storage.dart';
import 'login_response.dart';

class AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthRepository(this._api, this._storage);

  Future<LoginResponse> login({
    required String staffId,
    required String password,
  }) async {
    // The login screen surfaces auth failures inline, so a 401 here (bad
    // credentials) must not trip the global logout hook.
    final res = await _api.post(
      Endpoints.staffLogin,
      body: {'staffId': staffId, 'password': password},
      triggerLogoutOn401: false,
    );

    final data = res.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException(
        'Unexpected response from server.',
        ApiFailureKind.unknown,
      );
    }

    final login = LoginResponse.fromJson(data);
    if (login.authToken.isEmpty || login.roles.isEmpty) {
      throw const ApiException(
        'Login response was incomplete. Contact your developer.',
        ApiFailureKind.unknown,
      );
    }

    final previous = await _storage.activeRole;
    final active = (previous != null &&
        previous.isNotEmpty &&
        login.roles.contains(previous))
        ? previous
        : login.roles.first;

    await _storage.saveSession(
      token: login.authToken,
      refreshToken: login.refreshToken,
      staffId: login.staffId,
      staffName: login.staffName,
      institutionName: login.institutionName,
      roles: login.roles,
      activeRole: active,
    );

    return login;
  }

  Future<StoredSession?> restore() => _storage.read();

  Future<void> setActiveRole(String role) => _storage.setActiveRole(role);

  Future<void> signOut() => _storage.clear();

  Future<String> subscribe({
    required String institutionName,
    required String subscriptionCode,
  }) async {
    final res = await _api.post(
      Endpoints.schoolSubscription,
      body: {
        'institutionName': institutionName,
        'subscriptionCode': subscriptionCode,
      },
      triggerLogoutOn401: false,
    );
    return _extractId(res.data, keys: const ['institutionId', 'id']);
  }

  /// Enroll a staff member (used for the first Principal after subscription).
  /// Returns the new staff id on success.
  Future<String> enrollStaff({
    required String firstName,
    required String lastName,
    required String gender,
    required String dateOfBirth, // yyyy-MM-dd
    required String email,
    required String phoneNumber,
    required String institutionId,
    required String password,
    required List<String> roles,
  }) async {
    final res = await _api.post(
      Endpoints.enrollStaff,
      body: {
        'firstName': firstName,
        'lastName': lastName,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'email': email,
        'phoneNumber': phoneNumber,
        'institutionId': institutionId,
        'password': password,
        'roles': roles,
      },
      triggerLogoutOn401: false,
    );
    return _extractId(res.data, keys: const ['staffId', 'id']);
  }

  /// The subscription/enrollment endpoints return the new id as the response
  /// body — either a bare string or a small JSON object.
  String _extractId(dynamic data, {required List<String> keys}) {
    if (data is String) return data.trim();
    if (data is Map) {
      for (final k in keys) {
        final v = data[k];
        if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
      }
      final msg = data['message'];
      if (msg != null) return msg.toString().trim();
    }
    return data?.toString().trim() ?? '';
  }
}