import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academics/data/academics_providers.dart';
import '../../../students/data/student_models.dart';
import '../../../students/data/student_providers.dart';
import '../../data/report_models.dart';
import '../../data/reports_providers.dart';
import '../report_widgets.dart';

/// Student Payments (student-payments): one student's fee position and full
/// payment history for a term. Preview only (no PDF endpoint).
/// Needs studentId + semesterId + gradeId (the student's class).
class StudentPaymentsReport extends ConsumerStatefulWidget {
  const StudentPaymentsReport({super.key});

  @override
  ConsumerState<StudentPaymentsReport> createState() =>
      _StudentPaymentsReportState();
}

class _StudentPaymentsReportState
    extends ConsumerState<StudentPaymentsReport> {
  String? _levelId; // gradeId
  String? _studentId;
  String? _semesterId;
  AsyncValue<StudentFeesReport?>? _result;
  bool _loading = false;

  Future<void> _run() async {
    if (_studentId == null || _semesterId == null || _levelId == null) return;
    setState(() => _loading = true);
    try {
      final report = await ref
          .read(reportsRepositoryProvider)
          .studentPayments(_studentId!, _semesterId!, _levelId!);
      if (!mounted) return;
      setState(() {
        _result = AsyncData(report);
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
    // Students of the chosen class (reuses the students-by-class provider).
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
                width: 200,
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
                  _studentId = null; // reset student when class changes
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
                label: 'Term',
                hint: 'Select term',
                value: _semesterId,
                width: 220,
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
              enabled: _levelId != null &&
                  _studentId != null &&
                  _semesterId != null &&
                  !_loading,
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
      return ReportStates.prompt('Choose a student',
          'Pick class, student and term, then Run.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (report) {
        if (report == null) {
          return ReportStates.empty(
              'No record', 'No fee record for this student and term.');
        }
        return _report(c, report);
      },
    );
  }

  Widget _report(AppColors c, StudentFeesReport r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary card.
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: AppRadius.card,
            border: Border.all(color: c.border, width: AppStroke.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.studentName,
                  style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
              Text('${r.studentId}  ·  ${r.levelName}  ·  ${r.semesterName}',
                  style: AppTypography.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                _stat(c, 'Total fees', r.totalFeesAmount),
                _stat(c, 'Paid', r.totalAmountPaid),
                _stat(c, 'Balance', r.feesBalance,
                    color: (double.tryParse(r.feesBalance.trim()) ?? 0) > 0
                        ? c.danger
                        : c.success),
              ]),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text('Payment history',
            style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: r.paymentHistory.isEmpty
              ? ReportStates.empty('No payments', 'No payments recorded yet.')
              : ReportTable(
                  header: _historyHeader(c),
                  itemCount: r.paymentHistory.length,
                  itemBuilder: (context, i) =>
                      _historyRow(c, r.paymentHistory[i]),
                ),
        ),
      ],
    );
  }

  Widget _stat(AppColors c, String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.caption.copyWith(color: c.textMuted)),
          const SizedBox(height: 2),
          Text(value.isEmpty ? '—' : value,
              style: AppTypography.metric
                  .copyWith(color: color ?? c.textPrimary)),
        ],
      ),
    );
  }

  Widget _historyHeader(AppColors c) {
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
        h('Date', 130),
        h('Amount', 110, a: TextAlign.right),
        h('Balance', 110, a: TextAlign.right),
        h('Paid by', null),
        h('Contact', 150),
      ]),
    );
  }

  Widget _historyRow(AppColors c, PaymentHistoryRow p) {
    Widget cell(String t, double? w, {TextAlign a = TextAlign.left}) {
      final child = Text(t.isEmpty ? '—' : t,
          textAlign: a,
          style: AppTypography.body.copyWith(color: c.textPrimary),
          maxLines: 1,
          overflow: TextOverflow.ellipsis);
      return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(children: [
        cell(p.dateOfPayment, 130),
        cell(p.amountPaid, 110, a: TextAlign.right),
        cell(p.feesBalance, 110, a: TextAlign.right),
        cell(p.personWhoPaid, null),
        cell(p.contactInfo, 150),
      ]),
    );
  }
}
