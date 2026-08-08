import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth token and the minimal session facts across launches,
/// using the OS secure store (Keychain / Credential Manager / libsecret).
///
/// Mirrors what the JavaFX `SessionManager` kept: token, staffId, staffName,
/// institutionName, the comma-joined roles, and the last active role.
class TokenStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'auth_token';
  static const _kStaffId = 'staff_id';
  static const _kStaffName = 'staff_name';
  static const _kInstitution = 'institution_name';
  static const _kRoles = 'roles_csv';
  static const _kActiveRole = 'active_role';

  Future<void> saveSession({
    required String token,
    required String staffId,
    required String staffName,
    required String institutionName,
    required List<String> roles,
    required String activeRole,
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kStaffId, value: staffId),
      _storage.write(key: _kStaffName, value: staffName),
      _storage.write(key: _kInstitution, value: institutionName),
      _storage.write(key: _kRoles, value: roles.join(',')),
      _storage.write(key: _kActiveRole, value: activeRole),
    ]);
  }

  Future<void> setActiveRole(String role) =>
      _storage.write(key: _kActiveRole, value: role);

  Future<String?> get token => _storage.read(key: _kToken);
  Future<String?> get staffId => _storage.read(key: _kStaffId);
  Future<String?> get staffName => _storage.read(key: _kStaffName);
  Future<String?> get institutionName => _storage.read(key: _kInstitution);
  Future<String?> get activeRole => _storage.read(key: _kActiveRole);

  Future<List<String>> get roles async {
    final csv = await _storage.read(key: _kRoles);
    if (csv == null || csv.isEmpty) return const [];
    return csv.split(',').where((r) => r.isNotEmpty).toList();
  }

  /// Rehydrate a full stored session, or null if nothing is stored.
  Future<StoredSession?> read() async {
    final t = await token;
    final id = await staffId;
    if (t == null || t.isEmpty || id == null || id.isEmpty) return null;
    return StoredSession(
      token: t,
      staffId: id,
      staffName: await staffName ?? '',
      institutionName: await institutionName ?? '',
      roles: await roles,
      activeRole: await activeRole ?? '',
    );
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kStaffId),
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
  final String staffId;
  final String staffName;
  final String institutionName;
  final List<String> roles;
  final String activeRole;

  const StoredSession({
    required this.token,
    required this.staffId,
    required this.staffName,
    required this.institutionName,
    required this.roles,
    required this.activeRole,
  });
}
