import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../academics/data/academics_models.dart';
import '../../academics/data/academics_providers.dart';
import '../../students/data/student_models.dart';
import '../../students/data/student_providers.dart';
import '../data/finance_providers.dart';

class FinanceContextBar extends ConsumerWidget {
  const FinanceContextBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final classesAsync = ref.watch(classesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final levelId = ref.watch(financeLevelIdProvider);
    final semesterId = ref.watch(financeSemesterIdProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_alt_rounded, size: 18, color: c.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text('Working in:',
              style: AppTypography.label.copyWith(color: c.textSecondary)),
          const SizedBox(width: AppSpacing.md),

          // Class
          _dropdown<String, ClassOption>(
            c,
            width: 220,
            hint: 'Class',
            value: levelId,
            async: classesAsync,
            itemsBuilder: (classes) => [
              for (final cls in classes)
                DropdownMenuItem(
                  value: cls.levelId,
                  child: Text(cls.levelName,
                      style: AppTypography.body.copyWith(color: c.textPrimary)),
                ),
            ],
            validate: (classes, v) =>
                classes.any((cl) => cl.levelId == v) ? v : null,
            onChanged: (v) {
              ref.read(financeLevelIdProvider.notifier).state = v;
              // Changing class clears the chosen student.
              ref.read(financeStudentIdProvider.notifier).state = null;
            },
          ),
          const SizedBox(width: AppSpacing.md),

          // Semester
          _dropdown<String, SemesterSummary>(
            c,
            width: 240,
            hint: 'Term',
            value: semesterId,
            async: semestersAsync,
            itemsBuilder: (semesters) => [
              for (final s in semesters)
                DropdownMenuItem(
                  value: s.semesterId,
                  child: Text('${s.semesterName}  (${s.academicYear})',
                      style: AppTypography.body.copyWith(color: c.textPrimary)),
                ),
            ],
            validate: (semesters, v) =>
                semesters.any((s) => s.semesterId == v) ? v : null,
            onChanged: (v) =>
                ref.read(financeSemesterIdProvider.notifier).state = v,
          ),
        ],
      ),
    );
  }


  Widget _dropdown<T, E>(
    AppColors c, {
    required double width,
    required String hint,
    required T? value,
    required AsyncValue<List<E>> async,
    required List<DropdownMenuItem<T>> Function(List<E>) itemsBuilder,
    required T? Function(List<E>, T?) validate,
    required ValueChanged<T?> onChanged,
  }) {
    return SizedBox(
      width: width,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          border: Border.all(color: c.borderStrong, width: AppStroke.hairline),
        ),
        child: DropdownButtonHideUnderline(
          child: async.when(
            loading: () => _staticHint(c, 'Loading…'),
            error: (_, __) => _staticHint(c, 'Unavailable'),
            data: (list) => DropdownButton<T>(
              value: validate(list, value),
              isExpanded: true,
              hint: Text(hint,
                  style: AppTypography.body.copyWith(color: c.inputPlaceholder)),
              icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
              dropdownColor: c.surfaceElevated,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              items: itemsBuilder(list),
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
  }

  Widget _staticHint(AppColors c, String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(text,
            style: AppTypography.body.copyWith(color: c.textMuted)),
      );
}
