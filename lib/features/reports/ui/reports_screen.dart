import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../data/report_catalogue.dart';
import 'reports/class_results_report.dart';
import 'reports/grade_payments_report.dart';
import 'reports/master_sheet_report.dart';
import 'reports/report_card_report.dart';
import 'reports/sba_report.dart';
import 'reports/student_payments_report.dart';
import 'reports/expenses_report.dart';

/// The Reporting Center. Shows the reports available to the current role as a
/// grid of cards; tapping one opens that report inline (with a back button).
/// Kept as internal navigation so each report needn't be a separate route.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String? _openReportId;

  void _open(String id) => setState(() => _openReportId = id);
  void _back() => setState(() => _openReportId = null);

  Widget _reportScreen(String id) {
    return switch (id) {
      'class-results' => const ClassResultsReport(),
      'master-score-sheet' => const MasterSheetReport(),
      'sba' => const SbaReport(),
      'report-card' => const ReportCardReport(),
      'grade-payments' => const GradePaymentsReport(),
      'student-payments' => const StudentPaymentsReport(),
      'expenses-report' => const ExpensesReport(),
      _ => const SizedBox.shrink(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final session = ref.watch(sessionProvider);
    final role = session?.role;

    if (_openReportId != null) {
      final def = ReportCatalogue.findById(_openReportId!);
      return _ReportHost(
        title: def?.title ?? 'Report',
        onBack: _back,
        child: _reportScreen(_openReportId!),
      );
    }

    final reports =
    role == null ? <ReportDefinition>[] : ReportCatalogue.reportsFor(role);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reporting Center',
              style: AppTypography.display.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text('Generate and download school reports.',
              style: AppTypography.body.copyWith(color: c.textSecondary)),
          const SizedBox(height: AppSpacing.xl),
          if (reports.isEmpty)
            Text('No reports are available for your role.',
                style: AppTypography.body.copyWith(color: c.textMuted))
          else
            LayoutBuilder(builder: (context, constraints) {
              // Responsive columns: ~320px per card.
              final cols = (constraints.maxWidth / 320).floor().clamp(1, 3);
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final r in reports)
                    SizedBox(
                      width: (constraints.maxWidth -
                          (cols - 1) * AppSpacing.lg) /
                          cols,
                      child: _ReportCard(def: r, onTap: () => _open(r.id)),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportDefinition def;
  final VoidCallback onTap;

  const _ReportCard({required this.def, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Material(
      color: c.surface,
      borderRadius: AppRadius.card,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        hoverColor: c.hover,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: AppRadius.card,
            border: Border.all(color: c.border, width: AppStroke.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: c.brand50,
                  borderRadius: const BorderRadius.all(AppRadius.mdR),
                ),
                child: Icon(def.icon, color: c.brand, size: 22),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(def.title,
                  style:
                  AppTypography.subtitle.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(def.description,
                  style: AppTypography.caption.copyWith(color: c.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text('Open',
                      style: AppTypography.caption.copyWith(
                          color: c.brand, fontWeight: FontWeight.w700)),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(Icons.arrow_forward_rounded, size: 14, color: c.brand),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Wraps an open report with a header + back button.
class _ReportHost extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Widget child;

  const _ReportHost({
    required this.title,
    required this.onBack,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: c.border, width: AppStroke.hairline),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: Icon(Icons.arrow_back_rounded, color: c.textSecondary),
                tooltip: 'Back to reports',
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(title,
                  style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
            ],
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}