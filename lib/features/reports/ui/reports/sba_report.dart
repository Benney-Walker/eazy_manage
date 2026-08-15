import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academics/data/academics_models.dart';
import '../../../academics/data/academics_providers.dart';
import '../../../students/data/student_providers.dart';
import '../../data/report_models.dart';
import '../../data/reports_providers.dart';
import '../report_widgets.dart';

/// SBA Report (sba): the school-based assessment component breakdown for one
/// subject in a class + term. Preview + PDF download (generate-sba-report).
class SbaReport extends ConsumerStatefulWidget {
  const SbaReport({super.key});

  @override
  ConsumerState<SbaReport> createState() => _SbaReportState();
}

class _SbaReportState extends ConsumerState<SbaReport> {
  String? _levelId;
  String? _subjectId;
  String? _semesterId;
  AsyncValue<List<SbaRow>>? _result;
  bool _loading = false;

  bool get _ready =>
      _levelId != null && _subjectId != null && _semesterId != null;

  Future<void> _run() async {
    if (!_ready) return;
    setState(() => _loading = true);
    try {
      final rows = await ref
          .read(reportsRepositoryProvider)
          .sba(_levelId!, _subjectId!, _semesterId!);
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
    final subjectsAsync = _levelId == null
        ? const AsyncData<List<SubjectSummary>>([])
        : ref.watch(reportSubjectsProvider(_levelId!));

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
                  _subjectId = null;
                }),
              ),
              ReportPicker(
                label: 'Subject',
                hint: _levelId == null ? 'Pick class first' : 'Select subject',
                value: _subjectId,
                width: 200,
                items: subjectsAsync.maybeWhen(
                  orElse: () => const [],
                  data: (subs) => [
                    for (final s in subs)
                      DropdownMenuItem(
                          value: s.subjectId, child: Text(s.subjectName)),
                  ],
                ),
                onChanged: (v) => setState(() => _subjectId = v),
              ),
              ReportPicker(
                label: 'Term',
                hint: 'Select term',
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
                    ? Endpoints.generateSbaReport(
                        _levelId!, _subjectId!, _semesterId!)
                    : null,
                suggestedName: 'SBA Report',
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
      return ReportStates.prompt('Choose class, subject and term',
          'Pick all three, then Run to preview — or Download PDF directly.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (rows) {
        if (rows.isEmpty) {
          return ReportStates.empty(
              'No records', 'No SBA records for this selection.');
        }
        return ReportTable(
          header: _header(c),
          itemCount: rows.length,
          itemBuilder: (context, i) => _row(c, rows[i]),
        );
      },
    );
  }

  static const double _ct1 = 64;
  static const double _gw = 64;
  static const double _ct2 = 64;
  static const double _proj = 64;
  static const double _cls = 74;
  static const double _exam = 74;
  static const double _calc = 78;

  Widget _header(AppColors c) {
    Widget h(String t, double? w, {TextAlign a = TextAlign.center}) {
      final child = Text(t,
          textAlign: a,
          maxLines: 2,
          style: AppTypography.caption
              .copyWith(color: c.textSecondary, fontWeight: FontWeight.w700));
      return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        h('Student', null, a: TextAlign.left),
        h('CT1', _ct1),
        h('GW', _gw),
        h('CT2', _ct2),
        h('Proj', _proj),
        h('Class', _cls),
        h('Exam', _exam),
        h('Exam /50', _calc),
      ]),
    );
  }

  Widget _row(AppColors c, SbaRow r) {
    Widget num(String t, double w) => SizedBox(
          width: w,
          child: Text(t.isEmpty ? '—' : t,
              textAlign: TextAlign.center,
              style: AppTypography.body.copyWith(color: c.textPrimary)),
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
              Text(r.studentId,
                  style: AppTypography.caption.copyWith(color: c.textMuted)),
            ],
          ),
        ),
        num(r.classTest1Score, _ct1),
        num(r.groupWorkScore, _gw),
        num(r.classTest2Score, _ct2),
        num(r.projectScore, _proj),
        num(r.classScore, _cls),
        num(r.examScore, _exam),
        num(r.calculatedExamScore, _calc),
      ]),
    );
  }
}
