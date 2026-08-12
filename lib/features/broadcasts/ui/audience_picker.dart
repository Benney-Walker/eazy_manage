import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../students/data/student_providers.dart';
import '../data/broadcast_models.dart';

/// A reusable audience picker: staff-role toggles + per-class toggles. Selected
/// values (role keys and/or class levelIds) are surfaced via [onChanged] as a
/// single flat list, matching the wire format (`audience: [...]`).
///
/// Both the SMS and Email composers embed one of these; each keeps its own
/// selection state via the [selected] set passed in.
class AudiencePicker extends ConsumerWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  const AudiencePicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(String value) {
    final next = {...selected};
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final classesAsync = ref.watch(classesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Audience',
            style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs),
        Text('Choose who receives this. You can mix staff roles and classes.',
            style: AppTypography.caption.copyWith(color: c.textMuted)),
        const SizedBox(height: AppSpacing.md),

        // Staff roles.
        Text('Staff roles',
            style: AppTypography.caption
                .copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final entry in BroadcastRoles.entries)
              _chip(c, label: entry.value, value: entry.key),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Classes.
        Text('Classes',
            style: AppTypography.caption
                .copyWith(color: c.textSecondary, fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        classesAsync.when(
          loading: () => Text('Loading classes…',
              style: AppTypography.caption.copyWith(color: c.textMuted)),
          error: (_, __) => Text('Classes unavailable',
              style: AppTypography.caption.copyWith(color: c.textMuted)),
          data: (classes) {
            if (classes.isEmpty) {
              return Text('No classes found.',
                  style: AppTypography.caption.copyWith(color: c.textMuted));
            }
            return Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final cls in classes)
                  _chip(c, label: cls.levelName, value: cls.levelId),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _chip(AppColors c, {required String label, required String value}) {
    final isSel = selected.contains(value);
    return GestureDetector(
      onTap: () => _toggle(value),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSel ? c.brand : c.surfaceAlt,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          border: Border.all(
            color: isSel ? c.brand : c.border,
            width: AppStroke.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(isSel ? Icons.check_rounded : Icons.add_rounded,
                size: 14, color: isSel ? c.onBrand : c.textSecondary),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(label,
                style: AppTypography.caption.copyWith(
                  color: isSel ? c.onBrand : c.textSecondary,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }
}
