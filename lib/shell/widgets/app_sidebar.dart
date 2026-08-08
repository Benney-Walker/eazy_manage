import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/navigation/nav_item.dart';
import '../../core/navigation/nav_registry.dart';
import '../../core/session/session.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';

/// The application sidebar — always dark slate in both themes (an identity
/// marker carried over from the JavaFX shell), modernized with smoother
/// spacing, an active pill with an accent indicator bar, and a collapse mode.
class AppSidebar extends ConsumerWidget {
  /// Currently-selected nav id (drives the active state).
  final String activeId;
  final ValueChanged<NavItem> onSelect;
  final bool collapsed;
  final VoidCallback onSignOut;

  const AppSidebar({
    super.key,
    required this.activeId,
    required this.onSelect,
    required this.collapsed,
    required this.onSignOut,
  });

  static const double expandedWidth = 268;
  static const double collapsedWidth = 76;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final session = ref.watch(sessionProvider);
    final sections = NavRegistry.sectionsFor(session.role);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      width: collapsed ? collapsedWidth : expandedWidth,
      color: c.sidebar,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _brandHeader(c),
          _divider(c),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              children: [
                for (final section in sections) ...[
                  _sectionLabel(c, section.title),
                  for (final item in section.items)
                    _navTile(context, c, item),
                  const SizedBox(height: AppSpacing.md),
                ],
              ],
            ),
          ),
          _divider(c),
          _userFooter(context, c, session),
        ],
      ),
    );
  }

  // ---- Brand header -------------------------------------------------------
  Widget _brandHeader(AppColors c) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: c.brand,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
            ),
            alignment: Alignment.center,
            child: Text(
              'E',
              style: AppTypography.subtitle.copyWith(
                color: c.onBrand,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'EazyManage',
                    style: AppTypography.subtitle.copyWith(
                      color: c.sidebarTextActive,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'School ERP',
                    style: AppTypography.caption.copyWith(color: c.sidebarTextMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---- Section label ------------------------------------------------------
  Widget _sectionLabel(AppColors c, String title) {
    if (collapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Divider(height: 1, indent: 20, endIndent: 20, color: Color(0x141E2A36)),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.sm,
      ),
      child: Text(
        title,
        style: AppTypography.eyebrow.copyWith(color: c.sidebarTextMuted),
      ),
    );
  }

  // ---- Nav tile -----------------------------------------------------------
  Widget _navTile(BuildContext context, AppColors c, NavItem item) {
    final active = item.id == activeId;

    final tile = Container(
      margin: EdgeInsets.symmetric(
        horizontal: collapsed ? AppSpacing.sm : AppSpacing.md,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: active ? c.sidebarHover : Colors.transparent,
        borderRadius: const BorderRadius.all(AppRadius.mdR),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelect(item),
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          hoverColor: c.sidebarHover.withValues(alpha: 0.5),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 0 : AppSpacing.md,
              vertical: AppSpacing.md - 2,
            ),
            child: Row(
              mainAxisAlignment:
                  collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: active ? c.sidebarActive : c.sidebarText,
                ),
                if (!collapsed) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      item.label,
                      style: AppTypography.button.copyWith(
                        color: active ? c.sidebarTextActive : c.sidebarText,
                        fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    // Active accent indicator bar on the left edge.
    final withIndicator = Stack(
      children: [
        tile,
        if (active)
          Positioned(
            left: collapsed ? 4 : 0,
            top: 8,
            bottom: 8,
            child: Container(
              width: 3,
              decoration: BoxDecoration(
                color: c.sidebarActive,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );

    if (collapsed) {
      return Tooltip(message: item.label, child: withIndicator);
    }
    return withIndicator;
  }

  // ---- User footer --------------------------------------------------------
  Widget _userFooter(BuildContext context, AppColors c, Session session) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            collapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.brand.withValues(alpha: 0.18),
              borderRadius: const BorderRadius.all(AppRadius.mdR),
            ),
            alignment: Alignment.center,
            child: Text(
              session.initials,
              style: AppTypography.label.copyWith(
                color: c.sidebarActive,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (!collapsed) ...[
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    session.fullName,
                    style: AppTypography.label.copyWith(color: c.sidebarTextActive),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    session.role.label,
                    style: AppTypography.caption.copyWith(color: c.sidebarTextMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Sign out',
              child: IconButton(
                onPressed: onSignOut,
                icon: Icon(Icons.logout_rounded, size: 18, color: c.sidebarText),
                splashRadius: 18,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _divider(AppColors c) =>
      Divider(height: 1, thickness: 1, color: c.sidebarDivider);
}
