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
import '../data/attendance_models.dart';
import '../data/attendance_providers.dart';

/// View-only attendance. Marking moved to the Eazy Attendance Android app; here
/// staff (everyone except the accountant) pick a class + semester, see which
/// dates have marked attendance, and open a date to view each student's status.
class AttendanceScreen extends ConsumerWidget {
  const AttendanceScreen({super.key});

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

  // ---- Picker bar: class + semester -----------------------------------------
  Widget _pickerBar(BuildContext context, WidgetRef ref, AppColors c) {
    final classesAsync = ref.watch(classesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final levelId = ref.watch(attendanceLevelIdProvider);
    final semesterId = ref.watch(attendanceSemesterIdProvider);

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
          Text('Viewing:',
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
                  onChanged: (v) {
                    ref.read(attendanceLevelIdProvider.notifier).state = v;
                    // Changing class invalidates the chosen date.
                    ref.read(attendanceDateProvider.notifier).state = null;
                  },
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 240,
            child: semestersAsync.when(
              loading: () => _hintBox(c, 'Loading semesters…'),
              error: (_, __) => _hintBox(c, 'Semesters unavailable'),
              data: (semesters) {
                final valid = semesters.any((s) => s.semesterId == semesterId)
                    ? semesterId
                    : null;
                return AcademicsDropdown<String>(
                  label: 'Semester',
                  value: valid,
                  hint: 'Select semester',
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
                      ref.read(attendanceSemesterIdProvider.notifier).state = v,
                );
              },
            ),
          ),
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
          child: Text(text,
              style: AppTypography.body.copyWith(color: c.textMuted)),
        ),
      ],
    );
  }

  // ---- Body -----------------------------------------------------------------
  Widget _body(BuildContext context, WidgetRef ref, AppColors c) {
    final classChosen = ref.watch(attendanceClassChosenProvider);
    if (!classChosen) {
      return const AcademicsEmpty(
        icon: Icons.event_available_rounded,
        title: 'Choose a class',
        subtitle:
            'Pick a class to see the dates attendance was marked, then open a date.',
      );
    }

    final date = ref.watch(attendanceDateProvider);

    // Two-pane: marked dates on the left, records for the selected date right.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 320, child: _datesPane(context, ref, c)),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: date == null
              ? const AcademicsEmpty(
                  icon: Icons.touch_app_rounded,
                  title: 'Pick a date',
                  subtitle: 'Select a marked date to view student attendance.',
                )
              : _recordsPane(context, ref, c),
        ),
      ],
    );
  }

  // ---- Left pane: marked dates ----------------------------------------------
  Widget _datesPane(BuildContext context, WidgetRef ref, AppColors c) {
    final async = ref.watch(markedDatesProvider);
    final selected = ref.watch(attendanceDateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Marked dates',
                  style: AppTypography.label.copyWith(color: c.textSecondary)),
            ),
            IconButton(
              onPressed: () => ref.invalidate(markedDatesProvider),
              icon: Icon(Icons.refresh_rounded, size: 18, color: c.textSecondary),
              splashRadius: 18,
              visualDensity: VisualDensity.compact,
              tooltip: 'Refresh',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: async.when(
            loading: () =>
                Center(child: CircularProgressIndicator(color: c.brand)),
            error: (e, _) => AcademicsEmpty(
              icon: Icons.cloud_off_rounded,
              title: 'Couldn\'t load dates',
              subtitle: e.toString().replaceFirst('ApiException: ', ''),
              action: AppButton.secondary(
                label: 'Retry',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.invalidate(markedDatesProvider),
              ),
            ),
            data: (dates) {
              if (dates.isEmpty) {
                return const AcademicsEmpty(
                  icon: Icons.event_busy_rounded,
                  title: 'No marked dates',
                  subtitle:
                      'Attendance hasn\'t been recorded for this class yet.',
                );
              }
              return DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.card,
                  border:
                      Border.all(color: c.border, width: AppStroke.hairline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: ListView.separated(
                    itemCount: dates.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.divider),
                    itemBuilder: (context, i) {
                      final d = dates[i];
                      final isSel = d.dateMarked == selected;
                      return Material(
                        color: isSel ? c.brand50 : Colors.transparent,
                        child: InkWell(
                          onTap: () => ref
                              .read(attendanceDateProvider.notifier)
                              .state = d.dateMarked,
                          hoverColor: c.hover,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg,
                              vertical: AppSpacing.md,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.event_rounded,
                                    size: 18,
                                    color: isSel ? c.brand : c.textMuted),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(d.dateMarked,
                                          style: AppTypography.bodyStrong
                                              .copyWith(
                                                  color: isSel
                                                      ? c.brand
                                                      : c.textPrimary)),
                                      Text(
                                        [
                                          if (d.dayMarked.isNotEmpty)
                                            d.dayMarked,
                                          if (d.staffName.isNotEmpty)
                                            'by ${d.staffName}',
                                        ].join('  ·  '),
                                        style: AppTypography.caption
                                            .copyWith(color: c.textSecondary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ---- Right pane: records for the selected date ----------------------------
  Widget _recordsPane(BuildContext context, WidgetRef ref, AppColors c) {
    // Records need a semester too; prompt if it's not chosen yet.
    final semesterId = ref.watch(attendanceSemesterIdProvider);
    if (semesterId == null) {
      return const AcademicsEmpty(
        icon: Icons.filter_alt_rounded,
        title: 'Choose a semester',
        subtitle: 'Select a semester above to load the records for this date.',
      );
    }

    final async = ref.watch(attendanceRecordsProvider);
    final date = ref.watch(attendanceDateProvider) ?? '';

    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load records',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(attendanceRecordsProvider),
        ),
      ),
      data: (records) {
        if (records.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.person_off_rounded,
            title: 'No records for this date',
            subtitle: 'There are no attendance entries for the selected date.',
          );
        }
        final present = records.where((r) => r.isPresent).length;
        final absent = records.length - present;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header.
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(date,
                          style: AppTypography.subtitle
                              .copyWith(color: c.textPrimary)),
                      Text('${records.length} students',
                          style: AppTypography.caption
                              .copyWith(color: c.textSecondary)),
                    ],
                  ),
                ),
                AppBadge(label: 'Present $present', intent: BadgeIntent.success),
                const SizedBox(width: AppSpacing.sm),
                AppBadge(label: 'Absent $absent', intent: BadgeIntent.danger),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.card,
                  border:
                      Border.all(color: c.border, width: AppStroke.hairline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: ListView.separated(
                    itemCount: records.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.divider),
                    itemBuilder: (context, i) {
                      final r = records[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: r.isPresent
                                    ? c.successSubtle
                                    : c.dangerSubtle,
                                borderRadius:
                                    const BorderRadius.all(AppRadius.mdR),
                              ),
                              child: Icon(
                                r.isPresent
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                size: 18,
                                color: r.isPresent ? c.success : c.danger,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(r.studentName,
                                      style: AppTypography.bodyStrong
                                          .copyWith(color: c.textPrimary),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                  Text(r.studentId,
                                      style: AppTypography.caption
                                          .copyWith(color: c.textSecondary)),
                                ],
                              ),
                            ),
                            AppBadge(
                              label: AttendanceStatus.label(r.status),
                              intent: r.isPresent
                                  ? BadgeIntent.success
                                  : BadgeIntent.danger,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
