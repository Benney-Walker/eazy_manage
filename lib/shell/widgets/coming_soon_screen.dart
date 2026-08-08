import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_badge.dart';

/// A tasteful "coming in a later phase" placeholder for nav destinations that
/// haven't been built yet. Keeps every route resolvable while the shell is in
/// place, so navigation can be exercised end-to-end from day one.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final String phaseNote;

  const ComingSoonScreen({
    super.key,
    required this.title,
    required this.icon,
    this.phaseNote = 'Arriving in a later phase',
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: c.brand50,
              borderRadius: const BorderRadius.all(AppRadius.xlR),
            ),
            child: Icon(icon, size: 34, color: c.brand),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.title.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'This screen is part of the incremental port.',
            style: AppTypography.body.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppBadge(label: phaseNote, intent: BadgeIntent.brand),
        ],
      ),
    );
  }
}
