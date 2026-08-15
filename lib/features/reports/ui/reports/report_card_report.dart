import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academics/data/academics_providers.dart';
import '../../../students/data/student_models.dart';
import '../../../students/data/student_providers.dart';
import '../../data/report_models.dart';
import '../../data/reports_providers.dart';
import '../report_widgets.dart';

/// Student Report Card (report-card): one student's full card for a semester —
/// subject scores, conduct, remarks, attendance, and position.
/// Preview + PDF download (generate-report-card).
class ReportCardReport extends ConsumerStatefulWidget {
  const ReportCardReport({super.key});

  @override
  ConsumerState<ReportCardReport> createState() => _ReportCardReportState();
}

class _ReportCardReportState extends ConsumerState<ReportCardReport> {
  String? _levelId;
  String? _studentId;
  String? _semesterId;
  AsyncValue<ReportCard?>? _result;
  bool _loading = false;

  bool get _ready => _studentId != null && _semesterId != null;

  Future<void> _run() async {
    if (!_ready) return;
    setState(() => _loading = true);
    try {
      final card = await ref
          .read(reportsRepositoryProvider)
          .reportCard(_studentId!, _semesterId!);
      if (!mounted) return;
      setState(() {
        _result = AsyncData(card);
        _loading = false;
      });
    } catch (e, st) {
      if (!mounted) return;
      setState(() {
        _result = AsyncError(e, st);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final classesAsync = ref.watch(classesProvider);
    final semestersAsync = ref.watch(semestersProvider);
    final studentsAsync = _levelId == null
        ? const AsyncData<List<StudentSummary>>([])
        : ref.watch(reportStudentsProvider(_levelId!));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportContextBar(
            pickers: [
              ReportPicker(
                label: 'Class',
                hint: 'Select class',
                value: _levelId,
                width: 180,
                items: classesAsync.maybeWhen(
                  orElse: () => const [],
                  data: (classes) => [
                    for (final cl in classes)
                      DropdownMenuItem(
                          value: cl.levelId, child: Text(cl.levelName)),
                  ],
                ),
                onChanged: (v) => setState(() {
                  _levelId = v;
                  _studentId = null;
                }),
              ),
              ReportPicker(
                label: 'Student',
                hint: _levelId == null ? 'Pick class first' : 'Select student',
                value: _studentId,
                width: 220,
                items: studentsAsync.maybeWhen(
                  orElse: () => const [],
                  data: (students) => [
                    for (final s in students)
                      DropdownMenuItem(
                          value: s.studentId, child: Text(s.studentName)),
                  ],
                ),
                onChanged: (v) => setState(() => _studentId = v),
              ),
              ReportPicker(
                label: 'Semester',
                hint: 'Select semester',
                value: _semesterId,
                width: 200,
                items: semestersAsync.maybeWhen(
                  orElse: () => const [],
                  data: (sems) => [
                    for (final s in sems)
                      DropdownMenuItem(
                          value: s.semesterId,
                          child: Text('${s.semesterName} (${s.academicYear})')),
                  ],
                ),
                onChanged: (v) => setState(() => _semesterId = v),
              ),
            ],
            trailing: Row(children: [
              ReportRunButton(
                  enabled: _ready && !_loading, busy: _loading, onRun: _run),
              const SizedBox(width: AppSpacing.sm),
              DownloadPdfButton(
                path: _ready
                    ? Endpoints.generateReportCard(_studentId!, _semesterId!)
                    : null,
                suggestedName: 'Report Card',
              ),
            ]),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _body(c)),
        ],
      ),
    );
  }

  Widget _body(AppColors c) {
    final result = _result;
    if (result == null) {
      return ReportStates.prompt('Choose a student',
          'Pick class, student and semester, then Run — or Download PDF.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (card) {
        if (card == null) {
          return ReportStates.empty(
              'No report card', 'No report card for this student and semester.');
        }
        return SingleChildScrollView(child: _card(c, card));
      },
    );
  }

  Widget _card(AppColors c, ReportCard r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: c.border, width: AppStroke.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (r.schoolName.isNotEmpty)
                Text(r.schoolName,
                    style: AppTypography.caption
                        .copyWith(color: c.textSecondary)),
              Text(r.studentName,
                  style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
              Text(
                  [
                    if (r.className.isNotEmpty) r.className,
                    if (r.semesterName.isNotEmpty) r.semesterName,
                    if (r.academicYear.isNotEmpty) r.academicYear,
                  ].join('  ·  '),
                  style:
                  AppTypography.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Wrap(spacing: AppSpacing.xl, runSpacing: AppSpacing.md, children: [
                _stat(c, 'Total', r.totalScore),
                _stat(c, 'Average', r.averageScore),
                _stat(
                    c,
                    'Position',
                    r.totalStudents.isEmpty
                        ? r.classPosition
                        : '${r.classPosition}/${r.totalStudents}'),
                _stat(c, 'Attendance',
                    '${r.attendancePresent}/${r.totalAttendance}'),
                if (r.promotedTo.isNotEmpty) _stat(c, 'Promoted to', r.promotedTo),
              ]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // Subject scores.
        Text('Subjects',
            style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        DecoratedBox(
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: c.border, width: AppStroke.hairline),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.card,
            child: Column(
              children: [
                Container(color: c.surfaceAlt, child: _subjHeader(c)),
                Divider(height: 1, color: c.divider),
                for (int i = 0; i < r.subjectScores.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: c.divider),
                  _subjRow(c, r.subjectScores[i]),
                ],
              ],
            ),
          ),
        ),

        if (r.conduct != null) ...[
          const SizedBox(height: AppSpacing.lg),
          Text('Conduct',
              style: AppTypography.label.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.sm),
          _conduct(c, r.conduct!),
        ],
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _stat(AppColors c, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: c.textMuted)),
        const SizedBox(height: 2),
        Text(value.isEmpty ? '—' : value,
            style: AppTypography.metric.copyWith(color: c.textPrimary)),
      ],
    );
  }

  Widget _subjHeader(AppColors c) {
    Widget h(String t, double? w, {TextAlign a = TextAlign.left}) {
      final child = Text(t,
          textAlign: a,
          style: AppTypography.caption
              .copyWith(color: c.textSecondary, fontWeight: FontWeight.w700));
      return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        h('Subject', null),
        h('Class', 74, a: TextAlign.right),
        h('Exam', 74, a: TextAlign.right),
        h('Total', 74, a: TextAlign.right),
        h('Grade', 70, a: TextAlign.center),
        h('Remark', 150),
      ]),
    );
  }

  Widget _subjRow(AppColors c, ReportCardSubject s) {
    Widget cell(String t, double? w,
        {TextAlign a = TextAlign.left, bool strong = false}) {
      final child = Text(t.isEmpty ? '—' : t,
          textAlign: a,
          style: (strong ? AppTypography.bodyStrong : AppTypography.body)
              .copyWith(color: c.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis);
      return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        cell(s.subjectName, null),
        cell(s.classScore, 74, a: TextAlign.right),
        cell(s.examScore, 74, a: TextAlign.right),
        cell(s.total, 74, a: TextAlign.right, strong: true),
        cell(s.grade, 70, a: TextAlign.center),
        cell(s.gradeDescriptor, 150),
      ]),
    );
  }

  Widget _conduct(AppColors c, ReportCardConduct cd) {
    Widget rating(String label, String value) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
            width: 160,
            child: Text(label,
                style: AppTypography.body
                    .copyWith(color: c.textSecondary))),
        Expanded(
          child: Text(value.isEmpty ? '—' : value.replaceAll('_', ' '),
              style:
              AppTypography.bodyStrong.copyWith(color: c.textPrimary)),
        ),
      ]),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          rating('Regular', cd.regular),
          rating('Punctual', cd.punctual),
          rating('Physical appearance', cd.physicalAppearance),
          rating('Social', cd.social),
          rating('Emotional', cd.emotional),
          rating('Cognitive skills', cd.cognitiveSkills),
          if (cd.facilitatorRemark.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('Facilitator remark',
                style: AppTypography.caption.copyWith(color: c.textMuted)),
            Text(cd.facilitatorRemark,
                style: AppTypography.body.copyWith(color: c.textPrimary)),
          ],
          if (cd.peculiarIssue.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('Peculiar issue',
                style: AppTypography.caption.copyWith(color: c.textMuted)),
            Text(cd.peculiarIssue,
                style: AppTypography.body.copyWith(color: c.textPrimary)),
          ],
        ],
      ),
    );
  }
}