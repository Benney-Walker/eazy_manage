import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../academics/ui/academics_widgets.dart';
import '../../staff/data/staff_providers.dart';
import '../data/audit_models.dart';
import '../data/audit_providers.dart';

/// Audit Logs (admin). Pick a date range — and optionally a staff member — to
/// view system activity. With no staff selected, all logs in the range load
/// (get-timely-logs); with one selected, only that staff's (get-staff-logs).
class AuditLogsScreen extends ConsumerWidget {
  const AuditLogsScreen({super.key});

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static DateTime? _parse(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterBar(context, ref, c),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _body(ref, c)),
        ],
      ),
    );
  }

  Widget _filterBar(BuildContext context, WidgetRef ref, AppColors c) {
    final filter = ref.watch(auditFilterProvider);
    final staffAsync = ref.watch(staffRosterProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: c.surfaceAlt,
        borderRadius: AppRadius.card,
        border: Border.all(color: c.border, width: AppStroke.hairline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 180,
            child: AcademicsDateField(
              label: 'From',
              value: _parse(filter.fromDate),
              onPick: (d) => ref.read(auditFilterProvider.notifier).state =
                  filter.copyWith(fromDate: _iso(d)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 180,
            child: AcademicsDateField(
              label: 'To',
              value: _parse(filter.toDate),
              onPick: (d) => ref.read(auditFilterProvider.notifier).state =
                  filter.copyWith(toDate: _iso(d)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 240,
            child: staffAsync.when(
              loading: () => _hintBox(c, 'Loading staff…'),
              error: (_, __) => _hintBox(c, 'Staff unavailable'),
              data: (staff) {
                final valid =
                    staff.any((s) => s.staffId == filter.selectedStaffId)
                        ? filter.selectedStaffId
                        : null;
                return AcademicsDropdown<String>(
                  label: 'Staff (optional)',
                  value: valid,
                  hint: 'All staff',
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text('All staff',
                          style:
                              AppTypography.body.copyWith(color: c.textPrimary)),
                    ),
                    for (final s in staff)
                      DropdownMenuItem(
                        value: s.staffId,
                        child: Text(s.staffName,
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary)),
                      ),
                  ],
                  onChanged: (v) {
                    final f = ref.read(auditFilterProvider);
                    ref.read(auditFilterProvider.notifier).state =
                        (v == null || v.isEmpty)
                            ? f.copyWith(clearStaff: true)
                            : f.copyWith(selectedStaffId: v);
                  },
                );
              },
            ),
          ),
          const Spacer(),
          AppButton.secondary(
            label: 'Refresh',
            icon: Icons.refresh_rounded,
            onPressed: filter.isReady
                ? () => ref.invalidate(auditLogsProvider)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _hintBox(AppColors c, String text) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(' ', style: AppTypography.label),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 44,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
          ),
          child:
              Text(text, style: AppTypography.body.copyWith(color: c.textMuted)),
        ),
      ],
    );
  }

  Widget _body(WidgetRef ref, AppColors c) {
    final filter = ref.watch(auditFilterProvider);
    if (!filter.isReady) {
      return const AcademicsEmpty(
        icon: Icons.receipt_long_rounded,
        title: 'Choose a date range',
        subtitle:
            'Pick a From and To date to view logs. Optionally filter by staff.',
      );
    }

    final async = ref.watch(auditLogsProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load logs',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(auditLogsProvider),
        ),
      ),
      data: (logs) {
        if (logs == null || logs.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.inbox_rounded,
            title: 'No logs',
            subtitle: 'No activity was recorded for this range.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.only(bottom: AppSpacing.sm, left: AppSpacing.xs),
              child: Text('${logs.length} entries',
                  style: AppTypography.caption.copyWith(color: c.textSecondary)),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.card,
                  border:
                      Border.all(color: c.border, width: AppStroke.hairline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: Column(
                    children: [
                      _headerRow(c),
                      Divider(height: 1, color: c.divider),
                      Expanded(
                        child: ListView.separated(
                          itemCount: logs.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: c.divider),
                          itemBuilder: (context, i) => _logRow(c, logs[i]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static const double _whenW = 150;
  static const double _actorW = 150;
  static const double _typeW = 130;
  static const double _statusW = 96;

  Widget _headerRow(AppColors c) {
    Widget h(String t, double? w) {
      final child = Text(t,
          style: AppTypography.caption
              .copyWith(color: c.textSecondary, fontWeight: FontWeight.w700));
      return w == null ? Expanded(child: child) : SizedBox(width: w, child: child);
    }

    return Container(
      color: c.surfaceAlt,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          h('When', _whenW),
          h('Actor', _actorW),
          h('Type', _typeW),
          h('Message', null),
          h('Status', _statusW),
        ],
      ),
    );
  }

  Widget _logRow(AppColors c, AuditLog log) {
    final (Color bg, Color fg) = log.isFailure
        ? (c.dangerSubtle, c.danger)
        : log.isSuccess
            ? (c.successSubtle, c.success)
            : (c.bgAlt, c.textSecondary);

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _whenW,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log.date,
                    style: AppTypography.body.copyWith(color: c.textPrimary)),
                Text(log.time,
                    style: AppTypography.caption.copyWith(color: c.textMuted)),
              ],
            ),
          ),
          SizedBox(
            width: _actorW,
            child: Text(log.createdBy.isEmpty ? '—' : log.createdBy,
                style: AppTypography.body.copyWith(color: c.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          SizedBox(
            width: _typeW,
            child: Text(log.type.isEmpty ? '—' : log.type,
                style: AppTypography.caption.copyWith(color: c.textSecondary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: Text(log.message,
                style: AppTypography.body.copyWith(color: c.textPrimary)),
          ),
          SizedBox(
            width: _statusW,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: const BorderRadius.all(AppRadius.smR),
                ),
                child: Text(
                  log.status.isEmpty ? '—' : log.status,
                  style: AppTypography.caption
                      .copyWith(color: fg, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
