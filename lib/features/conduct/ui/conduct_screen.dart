import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../academics/data/academics_providers.dart';
import '../../academics/ui/academics_widgets.dart';
import '../../students/data/student_providers.dart';
import '../data/conduct_models.dart';
import '../data/conduct_providers.dart';
import 'conduct_editor_sheet.dart';

/// Conduct: teaching staff pick a class + term, see each student's conduct
/// record with how complete it is, and open a student to rate the six conduct
/// categories and add remarks. Saves are local-first (instant, offline-safe).
class ConductScreen extends ConsumerWidget {
  const ConductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _pickerBar(context, ref, c),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _body(context, ref, c)),
        ],
      ),
    );
  }

  Widget _pickerBar(BuildContext context, WidgetRef ref, AppColors c) {
    final classesAsync = ref.watch(classesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final levelId = ref.watch(conductLevelIdProvider);
    final semesterId = ref.watch(conductSemesterIdProvider);

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
          SizedBox(
            width: 220,
            child: classesAsync.when(
              loading: () => _hintBox(c, 'Loading classes…'),
              error: (_, __) => _hintBox(c, 'Classes unavailable'),
              data: (classes) {
                final valid =
                classes.any((cl) => cl.levelId == levelId) ? levelId : null;
                return AcademicsDropdown<String>(
                  label: 'Class',
                  value: valid,
                  hint: 'Select class',
                  items: [
                    for (final cls in classes)
                      DropdownMenuItem(
                        value: cls.levelId,
                        child: Text(cls.levelName,
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary)),
                      ),
                  ],
                  onChanged: (v) =>
                  ref.read(conductLevelIdProvider.notifier).state = v,
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 240,
            child: semestersAsync.when(
              loading: () => _hintBox(c, 'Loading terms…'),
              error: (_, __) => _hintBox(c, 'Terms unavailable'),
              data: (semesters) {
                final valid = semesters.any((s) => s.semesterId == semesterId)
                    ? semesterId
                    : null;
                return AcademicsDropdown<String>(
                  label: 'Term',
                  value: valid,
                  hint: 'Select term',
                  items: [
                    for (final s in semesters)
                      DropdownMenuItem(
                        value: s.semesterId,
                        child: Text('${s.semesterName}  (${s.academicYear})',
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary)),
                      ),
                  ],
                  onChanged: (v) =>
                  ref.read(conductSemesterIdProvider.notifier).state = v,
                );
              },
            ),
          ),
          const Spacer(),
          Consumer(builder: (context, ref, _) {
            final ready = ref.watch(conductContextReadyProvider);
            return AppButton.secondary(
              label: 'Refresh',
              icon: Icons.refresh_rounded,
              onPressed:
              ready ? () => ref.invalidate(conductRecordsProvider) : null,
            );
          }),
        ],
      ),
    );
  }

  Widget _hintBox(AppColors c, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(' ', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
          ),
          child:
          Text(text, style: AppTypography.body.copyWith(color: c.textMuted)),
        ),
      ],
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, AppColors c) {
    final ready = ref.watch(conductContextReadyProvider);
    if (!ready) {
      return const AcademicsEmpty(
        icon: Icons.flag_rounded,
        title: 'Choose a class and term',
        subtitle: 'Pick both above to load the conduct records for the class.',
      );
    }

    final async = ref.watch(conductRecordsProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load conduct records',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(conductRecordsProvider),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.flag_outlined,
            title: 'No students',
            subtitle: 'There are no conduct records for this class and term.',
          );
        }
        final complete = records.where((r) => r.isComplete).length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(
                '${records.length} students  ·  $complete complete',
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Expanded(
              child: AcademicsListCard(
                itemCount: records.length,
                itemBuilder: (context, i) =>
                    _row(context, ref, c, records[i]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AppColors c,
      StudentConductRecord r) {
    return AcademicsRow(
      leadingIcon: Icons.person_rounded,
      title: r.studentName,
      subtitle: r.studentId,
      trailing: r.isComplete
          ? const AppBadge(label: 'Complete', intent: BadgeIntent.success)
          : AppBadge(
        label: '${r.ratedCount}/${ConductCategory.all.length} rated',
        intent: r.ratedCount == 0 ? BadgeIntent.neutral : BadgeIntent.warning,
      ),
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => ConductEditorSheet(record: r),
      ),
    );
  }
}
