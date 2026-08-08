import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/nav_item.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_controller.dart';

/// The workspace top bar. Carries the controls from the JavaFX shell:
/// sidebar toggle, the current page title, a search field, an offline-mode
/// indicator, a notification bell, and the light/dark toggle.
///
/// The role picker on the right is a development affordance for these early
/// phases so nav role-filtering can be previewed without real logins. It's
/// trivially removed once auth lands.
class AppTopBar extends ConsumerWidget {
  final String title;
  final VoidCallback onToggleSidebar;

  const AppTopBar({
    super.key,
    required this.title,
    required this.onToggleSidebar,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: c.surface,
        border: Border(bottom: BorderSide(color: c.border, width: AppStroke.hairline)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _iconButton(
            context,
            icon: Icons.menu_rounded,
            tooltip: 'Toggle sidebar',
            onTap: onToggleSidebar,
          ),
          const SizedBox(width: AppSpacing.md),
          Text(title, style: AppTypography.title.copyWith(color: c.textPrimary)),
          const SizedBox(width: AppSpacing.xl),
          Expanded(child: _searchField(context, c)),
          const SizedBox(width: AppSpacing.lg),
          _OfflineIndicator(),
          const SizedBox(width: AppSpacing.sm),
          _notificationBell(context, c, unread: 3),
          const SizedBox(width: AppSpacing.xs),
          _iconButton(
            context,
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            tooltip: 'Toggle light / dark',
            onTap: () => ref.read(themeModeProvider.notifier).toggle(),
          ),
          const SizedBox(width: AppSpacing.sm),
          const _RolePicker(),
        ],
      ),
    );
  }

  Widget _searchField(BuildContext context, AppColors c) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: SizedBox(
        height: 38,
        child: TextField(
          style: AppTypography.body.copyWith(color: c.textPrimary),
          cursorColor: c.brand,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Search students, classes, payments…',
            prefixIcon: Icon(Icons.search_rounded, size: 18, color: c.textMuted),
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            fillColor: c.bgAlt,
          ),
        ),
      ),
    );
  }

  Widget _notificationBell(BuildContext context, AppColors c, {required int unread}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _iconButton(
          context,
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: () {},
        ),
        if (unread > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: c.danger,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: c.surface, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                unread > 9 ? '9+' : '$unread',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _iconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final c = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          hoverColor: c.hover,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Icon(icon, size: 20, color: c.textSecondary),
          ),
        ),
      ),
    );
  }
}

/// Offline-mode chip — mirrors the JavaFX offline toggle. Tapping flips the
/// (local) state; the real offline engine binding lands with the sync phase.
class _OfflineIndicator extends StatefulWidget {
  @override
  State<_OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<_OfflineIndicator> {
  bool _offline = false;

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final (Color bg, Color fg, IconData icon, String label) = _offline
        ? (c.warningSubtle, c.warning, Icons.cloud_off_rounded, 'Offline')
        : (c.successSubtle, c.success, Icons.cloud_done_rounded, 'Online');

    return Tooltip(
      message: 'Toggle online / offline mode',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _offline = !_offline),
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm - 1,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: fg),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Development-only role switcher, so nav visibility can be previewed under
/// each role before real auth exists. Remove once login lands in Phase 3.
class _RolePicker extends ConsumerWidget {
  const _RolePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final role = ref.watch(sessionProvider).role;

    return Tooltip(
      message: 'Preview role (dev)',
      child: PopupMenuButton<AppRole>(
        initialValue: role,
        onSelected: (r) => ref.read(sessionProvider.notifier).previewRole(r),
        position: PopupMenuPosition.under,
        color: c.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          side: BorderSide(color: c.border, width: AppStroke.hairline),
        ),
        itemBuilder: (context) => [
          for (final r in AppRole.values)
            PopupMenuItem(
              value: r,
              child: Text(
                r.label,
                style: AppTypography.body.copyWith(color: c.textPrimary),
              ),
            ),
        ],
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: c.bgAlt,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.border, width: AppStroke.hairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.switch_account_rounded, size: 15, color: c.textSecondary),
              const SizedBox(width: AppSpacing.xs + 2),
              Text(
                role.label,
                style: AppTypography.caption.copyWith(
                  color: c.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.expand_more_rounded, size: 15, color: c.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
