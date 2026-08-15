import '../../../core/api/api_client.dart';
import '../../../core/api/api_config.dart';
import '../../../core/api/token_storage.dart';
import 'login_response.dart';

/// Owns the auth calls and session persistence. The controller talks to this
/// rather than Dio directly, keeping transport details out of state logic.
class AuthRepository {
  final ApiClient _api;
  final TokenStorage _storage;

  AuthRepository(this._api, this._storage);

  /// POST /auth/v1/staff-login. On success, persists the session (token +
  /// identity + roles + chosen active role) and returns the response.
  ///
  /// Active-role selection mirrors the JavaFX logic: keep the previously
  /// stored role if it's still one of the user's roles, otherwise take the
  /// first role in the response.
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
}