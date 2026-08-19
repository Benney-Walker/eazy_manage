import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/api_providers.dart';
import '../navigation/nav_item.dart';
import '../../features/auth/data/auth_repository.dart';

/// The signed-in user's identity, as the shell needs it.
@immutable
class Session {
  final String staffId;
  final String fullName;
  final String organizationName;

  final List<AppRole> roles;

  final AppRole role;

  const Session({
    required this.staffId,
    required this.fullName,
    required this.organizationName,
    required this.roles,
    required this.role,
  });

  /// Initials for the avatar (e.g. "Gertrude Ayensu" -> "GA").
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  bool get hasMultipleRoles => roles.length > 1;

  Session copyWith({AppRole? role}) => Session(
    staffId: staffId,
    fullName: fullName,
    organizationName: organizationName,
    roles: roles,
    role: role ?? this.role,
  );
}

/// The three states the app can be in with respect to authentication.
enum AuthStatus { unknown, authenticated, unauthenticated }

/// Immutable auth state: a status plus (when authenticated) the [Session].
@immutable
class AuthState {
  final AuthStatus status;
  final Session? session;

  const AuthState._(this.status, this.session);

  const AuthState.unknown() : this._(AuthStatus.unknown, null);
  const AuthState.unauthenticated() : this._(AuthStatus.unauthenticated, null);
  const AuthState.authenticated(Session session)
      : this._(AuthStatus.authenticated, session);

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

class AuthController extends Notifier<AuthState> {
  late final AuthRepository _repo;
  late final ApiClient _api;

  @override
  AuthState build() {
    _api = ref.read(apiClientProvider);
    final storage = ref.read(tokenStorageProvider);
    _repo = AuthRepository(_api, storage);

    // A 401 that survives a token refresh → treat as an expired session.
    _api.onUnauthorized = _onUnauthorized;
    // After a silent refresh, the repository persists the new access token;
    // nothing else in state needs to change (identity/roles are unchanged).
    _api.onTokenRefreshed = (_) {};

    // Kick off restore; state starts unknown and resolves asynchronously.
    _restore();
    return const AuthState.unknown();
  }

  Future<void> _restore() async {
    final stored = await _repo.restore();
    if (stored == null) {
      state = const AuthState.unauthenticated();
      return;
    }

    // Prime the client. The access token may be expired — that's fine; the
    // refresh token is what keeps the session alive across restarts.
    _api.setCredentials(
      token: stored.token,
      staffId: stored.staffId,
      refreshToken: stored.refreshToken,
    );

    if (stored.refreshToken.isNotEmpty) {
      // Proactively renew the access token so we open straight to the
      // dashboard with a valid token in hand.
      final result = await _api.refreshNow();
      if (result.outcome == TokenRefreshOutcome.rejected) {
        // The refresh token itself was rejected (401) — a genuinely dead
        // session. This is one of the only two cases that clears stored auth
        // (the other being an explicit sign-out).
        _api.clearCredentials();
        await _repo.signOut();
        state = const AuthState.unauthenticated();
        return;
      }
      // refreshed → we hold a fresh access token.
      // unavailable (offline / transient) → stay signed in; nothing cleared.

    } else if (stored.token.isEmpty) {
      // No refresh token and no access token — nothing to sustain the session.
      state = const AuthState.unauthenticated();
      return;
    }

    state = AuthState.authenticated(_sessionFromStored(stored));
  }

  /// Attempt login. Returns null on success, or a user-facing error message
  /// on failure (so the login screen can show it inline).
  Future<String?> login({
    required String staffId,
    required String password,
  }) async {
    try {
      final res = await _repo.login(staffId: staffId, password: password);

      _api.setCredentials(
        token: res.authToken,
        staffId: res.staffId,
        refreshToken: res.refreshToken,
      );

      final roles = res.roles.map(AppRole.fromBackend).toList();
      // Re-read the persisted active role to mirror repo's selection.
      final storedActive = await ref.read(tokenStorageProvider).activeRole;
      final active = AppRole.fromBackend(storedActive ?? res.roles.first);

      state = AuthState.authenticated(Session(
        staffId: res.staffId,
        fullName: res.staffName,
        organizationName: res.institutionName,
        roles: roles,
        role: roles.contains(active) ? active : roles.first,
      ));
      return null;
    } on ApiException catch (e) {
      return e.message;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  /// Switch the active role (for users who hold more than one).
  Future<void> switchRole(AppRole role) async {
    final current = state.session;
    if (current == null || !current.roles.contains(role)) return;
    await _repo.setActiveRole(role.backendValue);
    state = AuthState.authenticated(current.copyWith(role: role));
  }

  Future<void> signOut() async {
    _api.clearCredentials();
    await _repo.signOut();
    state = const AuthState.unauthenticated();
  }

  void _onUnauthorized(bool refreshTokenRejected) {
    // Every unresolved 401 sends the user to login. Storage is only cleared
    // when the refresh token itself was rejected (401) — an access-token 401
    // that couldn't be refreshed for a transient reason leaves the stored
    // session intact so it can recover.
    _api.clearCredentials();
    if (refreshTokenRejected) {
      _repo.signOut();
    }
    state = const AuthState.unauthenticated();
  }

  Session _sessionFromStored(dynamic stored) {
    final roles =
    (stored.roles as List<String>).map(AppRole.fromBackend).toList();
    final active = AppRole.fromBackend(stored.activeRole as String);
    return Session(
      staffId: stored.staffId as String,
      fullName: stored.staffName as String,
      organizationName: stored.institutionName as String,
      roles: roles.isEmpty ? [active] : roles,
      role: roles.contains(active) ? active : (roles.isEmpty ? active : roles.first),
    );
  }
}

final authProvider =
NotifierProvider<AuthController, AuthState>(AuthController.new);

/// The auth repository, for the pre-login flows (subscription, enrollment)
/// that run outside the authenticated session.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(apiClientProvider),
    ref.read(tokenStorageProvider),
  );
});

/// Convenience: the current [Session] (or null if not authenticated).
final sessionProvider = Provider<Session?>((ref) {
  return ref.watch(authProvider).session;
});