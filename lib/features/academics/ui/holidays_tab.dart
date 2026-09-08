import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../data/academics_models.dart';
import '../data/academics_providers.dart';
import 'academics_widgets.dart';

/// Holidays / calendar events: list them, add a new one, or edit an existing.
/// Each holiday has a type, a date range, and a linked semester.
class HolidaysTab extends ConsumerWidget {
  const HolidaysTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(holidaysProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Holidays & events',
                    style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
              ),
              AppButton.secondary(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.invalidate(holidaysProvider),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: 'Add holiday',
                icon: Icons.add_rounded,
                onPressed: () => _openEditor(context, ref, null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: async.when(
              loading: () =>
                  Center(child: CircularProgressIndicator(color: c.brand)),
              error: (e, _) => AcademicsEmpty(
                icon: Icons.cloud_off_rounded,
                title: 'Couldn\'t load holidays',
                subtitle: e.toString().replaceFirst('ApiException: ', ''),
                action: AppButton.secondary(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.invalidate(holidaysProvider),
                ),
              ),
              data: (holidays) {
                if (holidays.isEmpty) {
                  return const AcademicsEmpty(
                    icon: Icons.beach_access_rounded,
                    title: 'No holidays yet',
                    subtitle:
                    'Add holidays and school events to build the calendar.',
                  );
                }
                return AcademicsListCard(
                  itemCount: holidays.length,
                  itemBuilder: (context, i) =>
                      _row(context, ref, c, holidays[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, WidgetRef ref, AppColors c, Holiday h) {
    final range = h.startDate == h.endDate || h.endDate.isEmpty
        ? h.startDate
        : '${h.startDate} → ${h.endDate}';
    final sub = [
      if (range.isNotEmpty) range
    ].join('  ·  ');

    return AcademicsRow(
      leadingIcon: _iconFor(h.holidayName),
      title: HolidayTypes.label(h.holidayName),
      subtitle: sub.isEmpty ? null : sub,
      trailing: null,
      onTap: () => _openEditor(context, ref, h),
    );
  }

  IconData _iconFor(String type) {
    return switch (type.toUpperCase()) {
      HolidayTypes.publicHoliday => Icons.flag_rounded,
      HolidayTypes.midTermBreak => Icons.beach_access_rounded,
      HolidayTypes.schoolEvent => Icons.celebration_rounded,
      HolidayTypes.emergencyClosure => Icons.warning_amber_rounded,
      _ => Icons.event_rounded,
    };
  }

  void _openEditor(BuildContext context, WidgetRef ref, Holiday? holiday) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HolidayEditor(existing: holiday),
    );
  }
}

/// Add (existing == null) or edit a holiday.
class _HolidayEditor extends ConsumerStatefulWidget {
  final Holiday? existing;
  const _HolidayEditor({required this.existing});

  @override
  ConsumerState<_HolidayEditor> createState() => _HolidayEditorState();
}

class _HolidayEditorState extends ConsumerState<_HolidayEditor> {
  String? _type;
  DateTime? _start;
  DateTime? _end;

  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _type = e.holidayName.isEmpty ? null : e.holidayName;
      _start = _parse(e.startDate);
      _end = _parse(e.endDate);
    }
  }

  Future<void> _save(List<SemesterSummary> semesters) async {
    if (_type == null) {
      setState(() => _error = 'Select a holiday type.');
      return;
    }
    if (_start == null || _end == null) {
      setState(() => _error = 'Pick start and end dates.');
      return;
    }
    if (_end!.isBefore(_start!)) {
      setState(() => _error = 'End date cannot be before start date.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final holiday = Holiday(
      holidayId: widget.existing?.holidayId ?? 0,
      holidayName: _type!,
      startDate: _iso(_start!),
      endDate: _iso(_end!),
    );

    final repo = ref.read(academicsRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateHoliday(holiday);
      } else {
        await repo.addHoliday(holiday);
      }
      if (!mounted) return;
      ref.invalidate(holidaysProvider);
      notify(ref, context,
          action: _isEdit ? 'Update holiday' : 'Add holiday',
          message: _isEdit ? 'Holiday updated.' : 'Holiday added.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: _isEdit ? 'Update holiday' : 'Add holiday', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not save. Try again.';
      notify(ref, context,
          action: _isEdit ? 'Update holiday' : 'Add holiday', message: msg,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final semestersAsync = ref.watch(semestersProvider);

    return AcademicsSheet(
      title: _isEdit ? 'Edit holiday' : 'Add holiday',
      icon: Icons.beach_access_rounded,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AcademicsDropdown<String>(
            label: 'Type',
            value: _type,
            hint: 'Select holiday type',
            items: [
              for (final t in HolidayTypes.all)
                DropdownMenuItem(
                  value: t,
                  child: Text(HolidayTypes.label(t),
                      style: AppTypography.body.copyWith(color: c.textPrimary)),
                ),
            ],
            onChanged: (v) => setState(() => _type = v),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: AcademicsDateField(
                label: 'Start date',
                value: _start,
                onPick: (d) => setState(() => _start = d),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AcademicsDateField(
                label: 'End date',
                value: _end,
                onPick: (d) => setState(() => _end = d),
              ),
            ),
          ]),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AcademicsInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            const Spacer(),
            AppButton.ghost(
              label: 'Cancel',
              onPressed: _saving ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Save needs the semester list to resolve name + year, so read it
            // from the current async value (falls back to empty).
            AppButton.primary(
              label: _isEdit ? 'Save changes' : 'Add holiday',
              busy: _saving,
              onPressed: () => _save(semestersAsync.value ?? const []),
            ),
          ]),
        ],
      ),
    );
  }

  DateTime? _parse(String s) {
    if (s.isEmpty) return null;
    try {
      return DateTime.parse(s.length >= 10 ? s.substring(0, 10) : s);
    } catch (_) {
      return null;
    }
  }

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
