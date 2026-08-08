import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../navigation/nav_item.dart';

/// The signed-in user's identity, as the shell needs it.
///
/// In Phase 3 this gets populated from the real login response + JWT claims.
/// For Phase 2 it's seeded with a demo user so the shell renders and nav
/// role-filtering can be exercised. Swapping in real auth is a matter of
/// replacing [SessionController.build] and adding sign-in / sign-out.
@immutable
class Session {
  final String staffId;
  final String fullName;
  final String organizationName;
  final AppRole role;

  const Session({
    required this.staffId,
    required this.fullName,
    required this.organizationName,
    required this.role,
  });

  /// Initials for the avatar (e.g. "Gertrude Ayensu" -> "GA").
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first).toUpperCase();
  }

  Session copyWith({
    String? staffId,
    String? fullName,
    String? organizationName,
    AppRole? role,
  }) {
    return Session(
      staffId: staffId ?? this.staffId,
      fullName: fullName ?? this.fullName,
      organizationName: organizationName ?? this.organizationName,
      role: role ?? this.role,
    );
  }
}

class SessionController extends Notifier<Session> {
  @override
  Session build() {
    // TEMP demo session for Phase 2. Replaced by the real login flow in Phase 3.
    return const Session(
      staffId: 'STF100200',
      fullName: 'Gertrude Ayensu',
      organizationName: 'Daffodils International School',
      role: AppRole.administrator,
    );
  }

  /// Dev helper for the shell — lets us preview nav under each role until
  /// real auth arrives. Harmless to keep; the role picker is only wired in
  /// the top bar during these early phases.
  void previewRole(AppRole role) => state = state.copyWith(role: role);

  void signOut() {
    // Phase 3: clear token + secure storage, then route to auth.
  }
}

final sessionProvider =
    NotifierProvider<SessionController, Session>(SessionController.new);
