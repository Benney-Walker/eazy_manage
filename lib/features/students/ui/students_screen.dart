import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../data/student_models.dart';
import '../data/student_providers.dart';
import 'student_detail_sheet.dart';
import 'add_student_sheet.dart';

/// The Students home: pick a class, search the roster, tap a student to view
/// or edit their details, or enroll a new student.
class StudentsScreen extends ConsumerWidget {
  const StudentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final classesAsync = ref.watch(classesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(context, ref, c, classesAsync),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _roster(context, ref, c)),
        ],
      ),
    );
  }

  // ---- Toolbar: class picker + search + add -------------------------------
  Widget _toolbar(
      BuildContext context,
      WidgetRef ref,
      AppColors c,
      AsyncValue<List<ClassOption>> classesAsync,
      ) {
    final selected = ref.watch(selectedClassProvider);

    return Row(
      children: [
        // Class dropdown
        classesAsync.when(
          loading: () => _pill(c, 'Loading classes…'),
          error: (e, _) => _pill(c, 'Classes unavailable'),
          data: (classes) => Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              border: Border.all(color: c.borderStrong, width: AppStroke.hairline),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ClassOption>(
                value: selected,
                hint: Text('Select class',
                    style: AppTypography.body.copyWith(color: c.textMuted)),
                icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
                dropdownColor: c.surfaceElevated,
                borderRadius: const BorderRadius.all(AppRadius.mdR),
                items: [
                  for (final cls in classes)
                    DropdownMenuItem(
                      value: cls,
                      child: Text(cls.levelName,
                          style: AppTypography.body.copyWith(color: c.textPrimary)),
                    ),
                ],
                onChanged: (cls) {
                  ref.read(selectedClassProvider.notifier).state = cls;
                  ref.read(studentSearchProvider.notifier).state = '';
                },
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Search
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              enabled: selected != null,
              style: AppTypography.body.copyWith(color: c.textPrimary),
              cursorColor: c.brand,
              onChanged: (v) =>
              ref.read(studentSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: selected == null
                    ? 'Pick a class to search students'
                    : 'Search by name or ID…',
                prefixIcon:
                Icon(Icons.search_rounded, size: 18, color: c.textMuted),
                fillColor: c.surface,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        AppButton.primary(
          label: 'Enroll student',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => _openAddStudent(context, ref),
        ),
      ],
    );
  }

  Widget _pill(AppColors c, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: const BorderRadius.all(AppRadius.mdR),
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: Text(label, style: AppTypography.body.copyWith(color: c.textMuted)),
    );
  }

  // ---- Roster list --------------------------------------------------------
  Widget _roster(BuildContext context, WidgetRef ref, AppColors c) {
    final selected = ref.watch(selectedClassProvider);
    if (selected == null) {
      return _emptyState(
        c,
        icon: Icons.groups_2_rounded,
        title: 'Choose a class to begin',
        subtitle: 'Pick a class from the dropdown to see its students.',
      );
    }

    final filtered = ref.watch(filteredRosterProvider);

    return filtered.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => _emptyState(
        c,
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load students',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(rosterProvider),
        ),
      ),
      data: (students) {
        if (students.isEmpty) {
          final searching = ref.read(studentSearchProvider).isNotEmpty;
          return _emptyState(
            c,
            icon: searching ? Icons.search_off_rounded : Icons.person_off_rounded,
            title: searching ? 'No matches' : 'No students in this class',
            subtitle: searching
                ? 'Try a different name or ID.'
                : 'Enroll a student to get started.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(
                '${students.length} student${students.length == 1 ? '' : 's'}'
                    ' · ${selected.levelName}',
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: c.border, width: AppStroke.hairline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: ListView.separated(
                    itemCount: students.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.divider),
                    itemBuilder: (context, i) =>
                        _studentRow(context, ref, c, students[i]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _studentRow(
      BuildContext context, WidgetRef ref, AppColors c, StudentSummary s) {
    final initials = _initials(s.studentName);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openDetail(context, ref, s),
        hoverColor: c.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.brand50,
                  borderRadius: const BorderRadius.all(AppRadius.mdR),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: AppTypography.label.copyWith(
                    color: c.brand700,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.studentName,
                      style:
                      AppTypography.bodyStrong.copyWith(color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.studentId,
                      style: AppTypography.caption.copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Empty / error state ------------------------------------------------
  Widget _emptyState(
      AppColors c, {
        required IconData icon,
        required String title,
        required String subtitle,
        Widget? action,
      }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.bgAlt,
              borderRadius: const BorderRadius.all(AppRadius.lgR),
            ),
            child: Icon(icon, size: 30, color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action,
          ],
        ],
      ),
    );
  }

  // ---- Sheets -------------------------------------------------------------
  void _openDetail(BuildContext context, WidgetRef ref, StudentSummary s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StudentDetailSheet(studentId: s.studentId),
    );
  }

  void _openAddStudent(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddStudentSheet(),
    );
  }

  String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}