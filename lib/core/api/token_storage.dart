import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'auth_token';
  static const _kRefreshToken = 'refresh_token';
  static const _kStaffName = 'staff_name';
  static const _kInstitution = 'institution_name';
  static const _kRoles = 'roles_csv';
  static const _kActiveRole = 'active_role';
  static const _kThemeMode = 'theme_mode';

  Future<void> saveSession({
    required String token,
    required String refreshToken,
    required String staffName,
    required String institutionName,
    required List<String> roles,
    required String activeRole,
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kRefreshToken, value: refreshToken),
      _storage.write(key: _kStaffName, value: staffName),
      _storage.write(key: _kInstitution, value: institutionName),
      _storage.write(key: _kRoles, value: roles.join(',')),
      _storage.write(key: _kActiveRole, value: activeRole),
    ]);
  }

  /// Replace just the access token (after a successful refresh) without
  /// disturbing the rest of the stored session.
  Future<void> updateAccessToken(String token) =>
      _storage.write(key: _kToken, value: token);

  Future<void> setActiveRole(String role) =>
      _storage.write(key: _kActiveRole, value: role);

  Future<String?> get token => _storage.read(key: _kToken);
  Future<String?> get refreshToken => _storage.read(key: _kRefreshToken);
  Future<String?> get staffName => _storage.read(key: _kStaffName);
  Future<String?> get institutionName => _storage.read(key: _kInstitution);
  Future<String?> get activeRole => _storage.read(key: _kActiveRole);

  // ---- Theme preference (persisted separately from the session so it
  // survives sign-out) ----
  Future<void> setThemeMode(String mode) =>
      _storage.write(key: _kThemeMode, value: mode);
  Future<String?> get themeMode => _storage.read(key: _kThemeMode);

  Future<List<String>> get roles async {
    final csv = await _storage.read(key: _kRoles);
    if (csv == null || csv.isEmpty) return const [];
    return csv.split(',').where((r) => r.isNotEmpty).toList();
  }

  /// Rehydrate a full stored session, or null if nothing is stored.
  Future<StoredSession?> read() async {
    final t = await token;
    final rt = await refreshToken;

    final hasAccess = t != null && t.isNotEmpty;
    final hasRefresh = rt != null && rt.isNotEmpty;
    if (!hasAccess && !hasRefresh) return null;
    return StoredSession(
      token: t ?? '',
      refreshToken: rt ?? '',
      staffName: await staffName ?? '',
      institutionName: await institutionName ?? '',
      roles: await roles,
      activeRole: await activeRole ?? '',
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kStaffName),
      _storage.delete(key: _kInstitution),
      _storage.delete(key: _kRoles),
      _storage.delete(key: _kActiveRole),
    ]);
  }
}

/// A rehydrated session read back from secure storage on launch.
class StoredSession {
  final String token;
  final String refreshToken;
  final String staffName;
  final String institutionName;
  final List<String> roles;
  final String activeRole;

  const StoredSession({
    required this.token,
    required this.refreshToken,
    required this.staffName,
    required this.institutionName,
    required this.roles,
    required this.activeRole,
  });
}