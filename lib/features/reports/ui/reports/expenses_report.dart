import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/api/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../academics/data/academics_providers.dart';
import '../../../finance/data/finance_models.dart';
import '../../../finance/data/finance_providers.dart';
import '../report_widgets.dart';

/// Expenses Report (expenses-report): every expense recorded for a term.
/// View-only — reuses `read-expenses-records` — plus a PDF download
/// (`generate-expenses-report`). Accountant + Principal only.
class ExpensesReport extends ConsumerStatefulWidget {
  const ExpensesReport({super.key});

  @override
  ConsumerState<ExpensesReport> createState() => _ExpensesReportState();
}

class _ExpensesReportState extends ConsumerState<ExpensesReport> {
  String? _semesterId;
  AsyncValue<List<ExpensesRecord>>? _result;
  bool _loading = false;

  String _cedis(double v) => '₵${NumberFormat('#,##0.00').format(v)}';

  Future<void> _run() async {
    if (_semesterId == null) return;
    setState(() => _loading = true);
    try {
      final rows =
      await ref.read(financeRepositoryProvider).readExpenses(_semesterId!);
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
    final semestersAsync = ref.watch(semestersProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ReportContextBar(
            pickers: [
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
                          child:
                          Text('${s.semesterName} (${s.academicYear})')),
                  ],
                ),
                onChanged: (v) => setState(() {
                  _semesterId = v;
                  _result = null;
                }),
              ),
            ],
            trailing: Row(children: [
              ReportRunButton(
                enabled: _semesterId != null && !_loading,
                busy: _loading,
                onRun: _run,
              ),
              const SizedBox(width: AppSpacing.sm),
              DownloadPdfButton(
                path: _semesterId == null
                    ? null
                    : Endpoints.generateExpensesReport(_semesterId!),
                label: 'Download report',
                suggestedName: 'Expenses Report',
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
      return ReportStates.prompt(
          'Choose a term', 'Pick a term, then Run to see its expenses.');
    }
    return result.when(
      loading: () => ReportStates.loading(c),
      error: (e, _) => ReportStates.error(e, _run),
      data: (rows) {
        if (rows.isEmpty) {
          return ReportStates.empty(
              'No expenses', 'No expenses were recorded for this term.');
        }
        final total =
        rows.fold<double>(0, (sum, e) => sum + e.amountSpent);
        return ReportTable(
          header: _header(c, rows.length, total),
          itemCount: rows.length,
          itemBuilder: (context, i) => _row(c, rows[i]),
        );
      },
    );
  }

  Widget _header(AppColors c, int count, double total) {
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
        h('Description ($count)', null),
        h('Amount', 130, a: TextAlign.right),
        h('Date', 120, a: TextAlign.right),
      ]),
    );
  }

  Widget _row(AppColors c, ExpensesRecord e) {
    final hasExtra =
        e.extraInfo.isNotEmpty && e.extraInfo.toLowerCase() != 'no information';
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.description,
                  style: AppTypography.body.copyWith(color: c.textPrimary),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              if (hasExtra)
                Text(e.extraInfo,
                    style: AppTypography.caption.copyWith(color: c.textMuted),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        SizedBox(
          width: 130,
          child: Text(_cedis(e.amountSpent),
              textAlign: TextAlign.right,
              style: AppTypography.bodyStrong.copyWith(color: c.textPrimary)),
        ),
        SizedBox(
          width: 120,
          child: Text(e.expenseDate,
              textAlign: TextAlign.right,
              style: AppTypography.body.copyWith(color: c.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}