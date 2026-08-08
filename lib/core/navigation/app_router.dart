import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../session/session.dart';
import '../../shell/app_shell.dart';
import '../../shell/widgets/coming_soon_screen.dart';
import 'nav_item.dart';
import 'nav_registry.dart';

/// Builds the application router.
///
/// Every nav destination lives under a single [ShellRoute] so the shell
/// (sidebar + top bar) stays mounted across navigations. Each route currently
/// renders a [ComingSoonScreen]; as domains are ported, swap the builder for
/// the real screen — no routing changes needed.
///
/// A redirect enforces role access: if the signed-in role can't see the
/// requested destination, it's bounced to the dashboard.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/${NavRegistry.home}',
    redirect: (context, state) {
      final role = ref.read(sessionProvider).role;
      final path = state.uri.path;
      final id = path.startsWith('/') ? path.substring(1).split('/').first : path;

      // The showcase is always reachable (dev surface).
      if (id == 'showcase') return null;

      final item = NavRegistry.findById(id);
      // Unknown route → dashboard.
      if (item == null) return '/${NavRegistry.home}';
      // Role not permitted → dashboard.
      if (!item.availableFor(role)) return '/${NavRegistry.home}';
      return null;
    },
    routes: [
      // Standalone showcase (outside the shell), handy for design review.
      GoRoute(
        path: '/showcase',
        //builder: (context, state) => const ShowcaseScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.path, child: child),
        routes: [
          for (final item in NavRegistry.allItems)
            GoRoute(
              path: item.path,
              pageBuilder: (context, state) => NoTransitionPage(
                key: ValueKey(item.id),
                child: _destinationFor(item),
              ),
            ),
        ],
      ),
    ],
  );
});

/// Maps a nav item to its screen. Real screens replace these builders as each
/// domain is ported; for now every destination is a themed placeholder.
Widget _destinationFor(NavItem item) {
  // Phase note tailored so the roadmap is legible while clicking around.
  final note = switch (item.id) {
    'dashboard' => 'Phase 3 — first live slice',
    'students' => 'Phase 4',
    _ => 'Later phase',
  };
  return ComingSoonScreen(
    title: item.label,
    icon: item.icon,
    phaseNote: note,
  );
}
