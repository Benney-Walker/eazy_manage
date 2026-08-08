import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// Semantic intent for a badge — maps to the accent color families.
enum BadgeIntent { neutral, brand, success, info, warning, danger }

/// A small pill/badge for statuses, counts, and tags. Uses the subtle tint
/// of its intent as the background and the strong tone for the text, matching
/// the status-chip pattern from the JavaFX UI.
class AppBadge extends StatelessWidget {
  final String label;
  final BadgeIntent intent;
  final IconData? icon;

  const AppBadge({
    super.key,
    required this.label,
    this.intent = BadgeIntent.neutral,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    final (Color bg, Color fg) = switch (intent) {
      BadgeIntent.neutral => (c.surfaceAlt, c.textSecondary),
      BadgeIntent.brand => (c.brand50, c.brand700),
      BadgeIntent.success => (c.successSubtle, c.success),
      BadgeIntent.info => (c.infoSubtle, c.info),
      BadgeIntent.warning => (c.warningSubtle, c.warning),
      BadgeIntent.danger => (c.dangerSubtle, c.danger),
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.all(AppRadius.smR),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: fg,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
