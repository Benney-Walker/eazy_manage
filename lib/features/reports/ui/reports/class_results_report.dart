import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academics/data/academics_providers.dart';
import '../../../students/data/student_providers.dart';
import '../../data/report_models.dart';
import '../../data/reports_providers.dart';
import '../report_widgets.dart';

/// Class Results (class-results): each student's totals, average and position
/// for a class + term. Preview + PDF download (generate-class-report).
class ClassResultsReport extends ConsumerStatefulWidget {
  const ClassResultsReport({super.key});

  @override
  ConsumerState<ClassResultsReport> createState() =>
      _ClassResultsReportState();
}

class _ClassResultsReportState extends ConsumerState<ClassResultsReport> {
  String? _levelId;
  String? _semesterId;
  AsyncValue<List<ClassResultRow>>? _result;
  bool _loading = false;

  bool get _ready => _levelId != null && _semesterId != null;

  Future<void> _run() async {
    if (!_ready) return;
    setState(() => _loading = true);
    try {
      final rows = await ref
          .read(reportsRepositoryProvider)
          .classResults(_levelId!, _semesterId!);
      if (!mounted) return;
      setState(() {
        _result = AsyncData(rows);
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
                width: 220,
                items: classesAsync.maybeWhen(
                  orElse: () => const [],
                  data: (classes) => [
                    for (final cl in classes)
                      DropdownMenuItem(
                          value: cl.levelId, child: Text(cl.levelName)),
                  ],
                ),
                onChanged: (v) => setState(() => _levelId = v),
              ),
              ReportPicker(
                label: 'Term',
                hint: 'Select term',
                value: _semesterId,
                width: 240,
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
                    ? Endpoints.generateClassReport(_levelId!, _semesterId!)
                    : null,
                suggestedName: 'Class Results',
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
      return ReportStates.prompt('Choose class and term',
          'Pick both, then Run to preview — or Download PDF directly.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (rows) {
        if (rows.isEmpty) {
          return ReportStates.empty(
              'No results', 'No results for this class and term.');
        }
        return ReportTable(
          header: _header(c),
          itemCount: rows.length,
          itemBuilder: (context, i) => _row(c, rows[i]),
        );
      },
    );
  }

  Widget _header(AppColors c) {
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
        h('Student', null),
        h('Total', 90, a: TextAlign.right),
        h('Average', 90, a: TextAlign.right),
        h('Position', 90, a: TextAlign.right),
      ]),
    );
  }

  Widget _row(AppColors c, ClassResultRow r) {
    Widget cell(String t, double w, {bool strong = false}) => SizedBox(
          width: w,
          child: Text(t.isEmpty ? '—' : t,
              textAlign: TextAlign.right,
              style: (strong ? AppTypography.bodyStrong : AppTypography.body)
                  .copyWith(color: c.textPrimary)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.studentName,
                  style: AppTypography.body.copyWith(color: c.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              Text('${r.studentId}  ·  ${r.scores.length} subjects',
                  style: AppTypography.caption.copyWith(color: c.textMuted)),
            ],
          ),
        ),
        cell(r.totalScore, 90),
        cell(r.averageScore, 90),
        cell(
            r.totalStudents.isEmpty
                ? r.classPosition
                : '${r.classPosition}/${r.totalStudents}',
            90,
            strong: true),
      ]),
    );
  }
}
