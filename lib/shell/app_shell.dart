import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/navigation/nav_item.dart';
import '../core/navigation/nav_registry.dart';
import '../core/session/session.dart';
import '../core/theme/app_colors.dart';
import 'widgets/app_sidebar.dart';
import 'widgets/app_top_bar.dart';

class AppShell extends ConsumerStatefulWidget {
  /// The routed child (the current destination's screen).
  final Widget child;

  /// Current location path (e.g. '/students'), used to resolve the active id.
  final String location;

  const AppShell({super.key, required this.child, required this.location});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _collapsed = false;

  String get _activeId {
    // location is like '/students' -> 'students'
    final path = widget.location;
    final id = path.startsWith('/') ? path.substring(1) : path;
    // Guard against nested paths later (e.g. '/students/123').
    final firstSegment = id.split('/').first;
    return firstSegment.isEmpty ? NavRegistry.home : firstSegment;
  }

  String get _title {
    final item = NavRegistry.findById(_activeId);
    return item?.label ?? 'EazyManage';
  }

  void _onSelect(NavItem item) {
    if (item.id == _activeId) return;
    context.go(item.path);
  }

  void _onSignOut() {
    ref.read(sessionProvider.notifier).signOut();
    // Phase 3: context.go('/auth');
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Row(
        children: [
          AppSidebar(
            activeId: _activeId,
            collapsed: _collapsed,
            onSelect: _onSelect,
            onSignOut: _onSignOut,
          ),
          Expanded(
            child: Column(
              children: [
                AppTopBar(
                  title: _title,
                  onToggleSidebar: () =>
                      setState(() => _collapsed = !_collapsed),
                ),
                Expanded(
                  child: Container(
                    color: c.bg,
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
