import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../data/staff_models.dart';
import '../data/staff_providers.dart';
import 'staff_detail_sheet.dart';
import 'enroll_staff_sheet.dart';

/// The Staff home: a searchable roster. Tap a member to view/edit or reset
/// their password; enroll new staff from the toolbar.
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _toolbar(context, ref, c),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _roster(context, ref, c)),
        ],
      ),
    );
  }

  Widget _toolbar(BuildContext context, WidgetRef ref, AppColors c) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextField(
              style: AppTypography.body.copyWith(color: c.textPrimary),
              cursorColor: c.brand,
              onChanged: (v) =>
                  ref.read(staffSearchProvider.notifier).state = v,
              decoration: InputDecoration(
                hintText: 'Search staff by name or ID…',
                prefixIcon:
                    Icon(Icons.search_rounded, size: 18, color: c.textMuted),
                fillColor: c.surface,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        AppButton.secondary(
          label: 'Refresh',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(staffRosterProvider),
        ),
        const SizedBox(width: AppSpacing.sm),
        AppButton.primary(
          label: 'Enroll staff',
          icon: Icons.person_add_alt_1_rounded,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const EnrollStaffSheet(),
          ),
        ),
      ],
    );
  }

  Widget _roster(BuildContext context, WidgetRef ref, AppColors c) {
    final filtered = ref.watch(filteredStaffProvider);

    return filtered.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => _emptyState(
        c,
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load staff',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(staffRosterProvider),
        ),
      ),
      data: (staff) {
        if (staff.isEmpty) {
          final searching = ref.read(staffSearchProvider).isNotEmpty;
          return _emptyState(
            c,
            icon: searching ? Icons.search_off_rounded : Icons.badge_outlined,
            title: searching ? 'No matches' : 'No staff yet',
            subtitle: searching
                ? 'Try a different name or ID.'
                : 'Enroll a staff member to get started.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(
                '${staff.length} staff member${staff.length == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: AppRadius.card,
                  border: Border.all(color: c.border, width: AppStroke.hairline),
                ),
                child: ClipRRect(
                  borderRadius: AppRadius.card,
                  child: ListView.separated(
                    itemCount: staff.length,
                    separatorBuilder: (_, __) =>
                        Divider(height: 1, color: c.divider),
                    itemBuilder: (context, i) =>
                        _row(context, ref, c, staff[i]),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AppColors c, StaffSummary s) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => StaffDetailSheet(staffId: s.staffId),
        ),
        hoverColor: c.hover,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: c.infoSubtle,
                  borderRadius: const BorderRadius.all(AppRadius.mdR),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(s.staffName),
                  style: AppTypography.label.copyWith(
                    color: c.info,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.staffName,
                      style: AppTypography.bodyStrong
                          .copyWith(color: c.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      s.staffId,
                      style: AppTypography.caption
                          .copyWith(color: c.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(
    AppColors c, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: c.bgAlt,
              borderRadius: const BorderRadius.all(AppRadius.lgR),
            ),
            child: Icon(icon, size: 30, color: c.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(title, style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTypography.caption.copyWith(color: c.textSecondary),
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppSpacing.lg),
            action,
          ],
        ],
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
