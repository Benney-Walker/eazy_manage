import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// A dashboard metric card: an icon plate, a label, a large number, and an
/// optional trend line. This is the pattern the role dashboards will use for
/// their headline stats (Total Students, Fees Collected, etc.).
class AppMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? trendLabel;
  final bool trendUp;
  final Color? accent;

  const AppMetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trendLabel,
    this.trendUp = true,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final plate = accent ?? c.brand;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
        boxShadow: [
          BoxShadow(color: c.shadow, blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: plate,
                  borderRadius: const BorderRadius.all(Radius.circular(9)),
                ),
                child: Icon(icon, size: 18, color: c.onBrand),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: AppTypography.metric.copyWith(color: c.textPrimary)),
          if (trendLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(
                  trendUp ? Icons.trending_up : Icons.trending_down,
                  size: 15,
                  color: trendUp ? c.success : c.danger,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  trendLabel!,
                  style: AppTypography.caption.copyWith(
                    color: trendUp ? c.success : c.danger,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
