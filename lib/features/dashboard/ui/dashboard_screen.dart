import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/navigation/nav_item.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_metric_card.dart';
import '../data/dashboard_models.dart';
import '../data/dashboard_providers.dart';

/// The dashboard — the first data-backed screen. Renders a role-scoped set of
/// metric cards plus a supporting list (recent logs / transactions / absentees),
/// with proper loading and error states.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final session = ref.watch(sessionProvider);
    final async = ref.watch(dashboardProvider);

    return RefreshIndicator(
      color: c.brand,
      onRefresh: () async => ref.invalidate(dashboardProvider),
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          _greeting(c, session),
          const SizedBox(height: AppSpacing.xl),
          async.when(
            loading: () => _loading(c),
            error: (e, _) => _error(context, ref, c, e.toString()),
            data: (data) => _content(context, c, session, data),
          ),
        ],
      ),
    );
  }

  // ---- Greeting -----------------------------------------------------------
  Widget _greeting(AppColors c, Session? session) {
    final name = session?.fullName.split(' ').first ?? '';
    final org = session?.organizationName ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name.isEmpty ? 'Welcome back' : 'Welcome back, $name',
          style: AppTypography.display.copyWith(color: c.textPrimary),
        ),
        if (org.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(org, style: AppTypography.body.copyWith(color: c.textSecondary)),
        ],
      ],
    );
  }

  // ---- Loading ------------------------------------------------------------
  Widget _loading(AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.huge),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: c.brand),
            const SizedBox(height: AppSpacing.lg),
            Text('Loading your dashboard…',
                style: AppTypography.body.copyWith(color: c.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ---- Error --------------------------------------------------------------
  Widget _error(BuildContext context, WidgetRef ref, AppColors c, String message) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xxl),
      child: Center(
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: c.dangerSubtle,
                  borderRadius: const BorderRadius.all(AppRadius.lgR),
                ),
                child: Icon(Icons.cloud_off_rounded, color: c.danger, size: 26),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Couldn\'t load the dashboard',
                  style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  message.replaceFirst('ApiException: ', ''),
                  textAlign: TextAlign.center,
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton.primary(
                label: 'Try again',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.invalidate(dashboardProvider),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Content ------------------------------------------------------------
  Widget _content(
      BuildContext context, AppColors c, Session? session, DashboardData d) {
    final role = session?.role ?? AppRole.generalStaff;
    final cards = _metricsFor(role, c, d);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final perRow = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 560
                    ? 2
                    : 1;
            final spacing = AppSpacing.lg;
            final cardWidth =
                (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final card in cards)
                  SizedBox(width: cardWidth, child: card),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        _supportingSection(context, c, role, d),
      ],
    );
  }

  List<Widget> _metricsFor(AppRole role, AppColors c, DashboardData d) {
    String n(int? v) => v == null ? '—' : NumberFormat.decimalPattern().format(v);
    String cedis(int? v) => v == null ? '—' : '₵${NumberFormat.decimalPattern().format(v)}';

    switch (role) {
      case AppRole.principal:
        return [
          AppMetricCard(icon: Icons.groups_rounded, label: 'Students', value: n(d.totalStudents)),
          AppMetricCard(icon: Icons.badge_rounded, label: 'Staff', value: n(d.totalStaff), accent: c.info),
          AppMetricCard(icon: Icons.school_rounded, label: 'Teaching Staff', value: n(d.totalTeachingStaff), accent: c.brand400),
          AppMetricCard(icon: Icons.payments_rounded, label: 'Fees Collected', value: cedis(d.feesPaid), accent: c.success),
        ];
      case AppRole.administrator:
        return [
          AppMetricCard(icon: Icons.groups_rounded, label: 'Students', value: n(d.totalStudents)),
          AppMetricCard(icon: Icons.badge_rounded, label: 'Staff', value: n(d.totalStaff), accent: c.info),
          AppMetricCard(icon: Icons.school_rounded, label: 'Teaching Staff', value: n(d.totalTeachingStaff), accent: c.brand400),
        ];
      case AppRole.accountant:
        return [
          AppMetricCard(icon: Icons.account_balance_wallet_rounded, label: 'Total Fees', value: cedis(d.totalFees)),
          AppMetricCard(icon: Icons.payments_rounded, label: 'Fees Collected', value: cedis(d.feesPaid), accent: c.success),
          AppMetricCard(icon: Icons.groups_rounded, label: 'Students', value: n(d.totalStudents), accent: c.info),
        ];
      case AppRole.teachingStaff:
      case AppRole.generalStaff:
        return [
          AppMetricCard(icon: Icons.groups_rounded, label: 'Students', value: n(d.totalStudents)),
          AppMetricCard(icon: Icons.person_off_rounded, label: 'Absent Today', value: n(d.absentStudents.length), accent: c.warning),
        ];
    }
  }

  Widget _supportingSection(
      BuildContext context, AppColors c, AppRole role, DashboardData d) {
    switch (role) {
      case AppRole.accountant:
        return _listCard(
          c,
          title: 'Recent transactions',
          empty: 'No recent transactions.',
          rows: d.recentTransactions
              .map((t) => _RowData(t.studentName, t.amount, t.date))
              .toList(),
          leadingIcon: Icons.receipt_rounded,
        );
      case AppRole.principal:
      case AppRole.administrator:
        return _listCard(
          c,
          title: 'Recent activity',
          empty: 'No recent activity.',
          rows: d.recentLogs
              .map((l) => _RowData(l.action, l.createdBy, l.date))
              .toList(),
          leadingIcon: Icons.history_rounded,
        );
      case AppRole.teachingStaff:
      case AppRole.generalStaff:
        return _listCard(
          c,
          title: 'Absent today',
          empty: 'No absentees recorded today.',
          rows: d.absentStudents
              .map((s) => _RowData(s.studentName, s.className, ''))
              .toList(),
          leadingIcon: Icons.event_busy_rounded,
        );
    }
  }

  Widget _listCard(
    AppColors c, {
    required String title,
    required String empty,
    required List<_RowData> rows,
    required IconData leadingIcon,
  }) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: AppSectionHeader(title: title),
          ),
          Divider(height: 1, color: c.divider),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xxl),
              child: Center(
                child: Text(empty,
                    style: AppTypography.body.copyWith(color: c.textMuted)),
              ),
            )
          else
            ...rows.take(8).map((r) => _row(c, r, leadingIcon)),
        ],
      ),
    );
  }

  Widget _row(AppColors c, _RowData r, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: c.brand50,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
            ),
            child: Icon(icon, size: 16, color: c.brand),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.primary.isEmpty ? '—' : r.primary,
                  style: AppTypography.bodyStrong.copyWith(color: c.textPrimary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (r.secondary.isNotEmpty)
                  Text(
                    r.secondary,
                    style: AppTypography.caption.copyWith(color: c.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (r.trailing.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.md),
            Text(
              r.trailing,
              style: AppTypography.caption.copyWith(color: c.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _RowData {
  final String primary;
  final String secondary;
  final String trailing;
  const _RowData(this.primary, this.secondary, this.trailing);
}
