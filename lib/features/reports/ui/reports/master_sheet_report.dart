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

/// Master Score Sheet (master-score-sheet): a wide grid of every student
/// against every subject total, with student totals/averages/position.
/// Preview + PDF download (generate-master-sheet).
class MasterSheetReport extends ConsumerStatefulWidget {
  const MasterSheetReport({super.key});

  @override
  ConsumerState<MasterSheetReport> createState() => _MasterSheetReportState();
}

class _MasterSheetReportState extends ConsumerState<MasterSheetReport> {
  String? _levelId;
  String? _semesterId;
  AsyncValue<MasterSheet?>? _result;
  bool _loading = false;

  bool get _ready => _levelId != null && _semesterId != null;

  Future<void> _run() async {
    if (!_ready) return;
    setState(() => _loading = true);
    try {
      final sheet = await ref
          .read(reportsRepositoryProvider)
          .masterSheet(_levelId!, _semesterId!);
      if (!mounted) return;
      setState(() {
        _result = AsyncData(sheet);
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
                label: 'Semester',
                hint: 'Select semester',
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
                    ? Endpoints.generateMasterSheet(_levelId!, _semesterId!)
                    : null,
                suggestedName: 'Master Score Sheet',
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
      return ReportStates.prompt('Choose class and semester',
          'Pick both, then Run to preview — or Download PDF directly.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (sheet) {
        if (sheet == null || sheet.records.isEmpty) {
          return ReportStates.empty(
              'No data', 'No master sheet data for this class and semester.');
        }
        return _grid(c, sheet);
      },
    );
  }

  static const double _nameW = 200;
  static const double _subjW = 84;
  static const double _totW = 84;
  static const double _posW = 64;

  Widget _grid(AppColors c, MasterSheet sheet) {
    // Horizontal scroll for many subjects; the whole grid scrolls together.
    final tableWidth = _nameW +
        sheet.subjects.length * _subjW +
        _totW * 2 +
        _posW +
        AppSpacing.lg * 2;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.card,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: tableWidth,
            child: Column(
              children: [
                Container(color: c.surfaceAlt, child: _header(c, sheet)),
                Divider(height: 1, color: c.divider),
                Expanded(
                  child: ListView.separated(
                    itemCount: sheet.records.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.divider),
                    itemBuilder: (context, i) =>
                        _row(c, sheet, sheet.records[i]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(AppColors c, MasterSheet sheet) {
    Widget h(String t, double w, {TextAlign a = TextAlign.center}) => SizedBox(
          width: w,
          child: Text(t,
              textAlign: a,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                  color: c.textSecondary, fontWeight: FontWeight.w700)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        h('Student', _nameW, a: TextAlign.left),
        for (final subj in sheet.subjects) h(subj, _subjW),
        h('Total', _totW),
        h('Avg', _totW),
        h('Pos', _posW),
      ]),
    );
  }

  Widget _row(AppColors c, MasterSheet sheet, MasterSheetRow r) {
    String fmt(double v) => v == v.roundToDouble()
        ? v.toStringAsFixed(0)
        : v.toStringAsFixed(1);

    Widget num(String t, double w, {bool strong = false}) => SizedBox(
          width: w,
          child: Text(t,
              textAlign: TextAlign.center,
              style: (strong ? AppTypography.bodyStrong : AppTypography.body)
                  .copyWith(color: c.textPrimary)),
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        SizedBox(
          width: _nameW,
          child: Text(r.studentName,
              style: AppTypography.body.copyWith(color: c.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
        for (final subj in sheet.subjects)
          num(
            r.subjectScores.containsKey(subj)
                ? fmt(r.subjectScores[subj]!)
                : '—',
            _subjW,
          ),
        num(fmt(r.studentTotalScore), _totW, strong: true),
        num(fmt(r.studentAverageScore), _totW),
        num(r.position == 0 ? '—' : '${r.position}', _posW, strong: true),
      ]),
    );
  }
}
