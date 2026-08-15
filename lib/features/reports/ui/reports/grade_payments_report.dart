import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academics/data/academics_providers.dart';
import '../../../students/data/student_providers.dart';
import '../../data/report_models.dart';
import '../../data/reports_providers.dart';
import '../report_widgets.dart';

/// Class Payments (grade-payments): fees paid/outstanding for every student in
/// a class for a term. Preview only (no PDF endpoint).
class GradePaymentsReport extends ConsumerStatefulWidget {
  const GradePaymentsReport({super.key});

  @override
  ConsumerState<GradePaymentsReport> createState() =>
      _GradePaymentsReportState();
}

class _GradePaymentsReportState extends ConsumerState<GradePaymentsReport> {
  String? _levelId;
  String? _semesterId;
  AsyncValue<List<GradeFeesRow>>? _result;
  bool _loading = false;

  Future<void> _run() async {
    if (_levelId == null || _semesterId == null) return;
    setState(() => _loading = true);
    try {
      final rows = await ref
          .read(reportsRepositoryProvider)
          .gradePayments(_levelId!, _semesterId!);
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
                      DropdownMenuItem(value: cl.levelId, child: Text(cl.levelName)),
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
            trailing: ReportRunButton(
              enabled: _levelId != null && _semesterId != null && !_loading,
              busy: _loading,
              onRun: _run,
            ),
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
          'Pick both, then Run to see class payments.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (rows) {
        if (rows.isEmpty) {
          return ReportStates.empty(
              'No records', 'No payment data for this class and term.');
        }
        return ReportTable(
          header: _header(c),
          itemCount: rows.length,
          itemBuilder: (context, i) => _row(c, rows[i]),
        );
      },
    );
  }

  Widget _cellText(AppColors c, String t, double? w,
      {bool strong = false, Color? color, TextAlign align = TextAlign.left}) {
    final child = Text(t,
        textAlign: align,
        style: (strong ? AppTypography.bodyStrong : AppTypography.body)
            .copyWith(color: color ?? c.textPrimary),
        maxLines: 1,
        overflow: TextOverflow.ellipsis);
    return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
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
        h('To pay', 120, a: TextAlign.right),
        h('Paid', 120, a: TextAlign.right),
        h('Outstanding', 130, a: TextAlign.right),
      ]),
    );
  }

  Widget _row(AppColors c, GradeFeesRow r) {
    final outstanding = double.tryParse(r.outstanding.trim()) ?? 0;
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
        _cellText(c, r.totalAmountToPay, 120, align: TextAlign.right),
        _cellText(c, r.amountPayed, 120, align: TextAlign.right),
        _cellText(c, r.outstanding, 130,
            strong: true,
            align: TextAlign.right,
            color: outstanding > 0 ? c.danger : c.success),
      ]),
    );
  }
}
