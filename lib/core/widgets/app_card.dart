import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// A surface card — the Flutter equivalent of `.surface-card` in the JavaFX
/// design system. Hairline border + soft shadow + rounded corners.
///
/// Unlike the old JavaFX cards which leaned on hard borders, this uses a
/// subtle elevation shadow (Flutter renders these cleanly) plus a hairline
/// so cards read as gently lifted off the page.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool elevated;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.elevated = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final decoration = BoxDecoration(
      color: c.surface,
      borderRadius: AppRadius.card,
      border: Border.all(color: c.border, width: AppStroke.hairline),
      boxShadow: elevated
          ? [
              BoxShadow(
                color: c.shadow,
                blurRadius: 12,
                offset: const Offset(0, 2),
              ),
            ]
          : null,
    );

    final content = Padding(padding: padding, child: child);

    if (onTap == null) {
      return DecoratedBox(decoration: decoration, child: content);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Ink(decoration: decoration, child: content),
      ),
    );
  }
}

/// A small section header: an eyebrow-style title with an optional trailing
/// action, used at the top of card sections and panels.
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.subtitle.copyWith(color: c.textPrimary),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
