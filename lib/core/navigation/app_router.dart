import 'package:eazy_manage/features/staff/ui/staff_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../session/session.dart';
import '../theme/app_colors.dart';
import '../../features/auth/ui/login_screen.dart';
import '../../features/academics/ui/academic_setup_screen.dart';
import '../../features/dashboard/ui/dashboard_screen.dart';
import '../../features/finance/ui/finance_screen.dart';
import '../../features/settings/ui/settings_screen.dart';
import '../../features/staff/ui/staff_screen.dart';
import '../../features/students/ui/students_screen.dart';
import '../../shell/app_shell.dart';
import '../../shell/widgets/coming_soon_screen.dart';
import 'nav_item.dart';
import 'nav_registry.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/${NavRegistry.home}',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final path = state.uri.path;
      final id = path.startsWith('/') ? path.substring(1).split('/').first : path;

      // While restoring a stored session, hold on the splash.
      if (auth.status == AuthStatus.unknown) {
        return path == '/splash' ? null : '/splash';
      }

      final loggingIn = path == '/auth';
      final onSplash = path == '/splash';

      // Not signed in → only /auth is allowed.
      if (!auth.isAuthenticated) {
        return loggingIn ? null : '/auth';
      }

      // Signed in but sitting on /auth or /splash → go to the dashboard.
      if (loggingIn || onSplash) {
        return '/${NavRegistry.home}';
      }

      // Role guard for shell destinations.
      final item = NavRegistry.findById(id);
      if (item == null) return '/${NavRegistry.home}';
      final role = auth.session?.role;
      if (role != null && !item.availableFor(role)) {
        return '/${NavRegistry.home}';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (context, state) => const _Splash()),
      GoRoute(path: '/auth', builder: (context, state) => const LoginScreen()),

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

Widget _destinationFor(NavItem item) {
  return switch (item.id) {
    'dashboard' => const DashboardScreen(),
    'students' => const StudentsScreen(),
    'staff' => const StaffScreen(),
    'academic-setup' => const AcademicSetupScreen(),
    'finance' => const FinanceScreen(),
    'settings' => const SettingsScreen(),
    _ => ComingSoonScreen(
        title: item.label, icon: item.icon, phaseNote: 'Later phase'),
  };
}

class _AuthRefresh extends ChangeNotifier {
  _AuthRefresh(Ref ref) {
    _sub = ref.listen<AuthState>(
      authProvider,
          (_, __) => notifyListeners(),
      fireImmediately: false,
    );
  }
  late final ProviderSubscription<AuthState> _sub;

  @override
  void dispose() {
    _sub.close();
    super.dispose();
  }
}

/// A minimal splash shown while the stored session is being restored.
class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.brand,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: const Text('E',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: c.brand),
            ),
          ],
        ),
      ),
    );
  }
}