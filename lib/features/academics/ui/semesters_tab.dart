import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/academics_models.dart';
import '../data/academics_providers.dart';
import 'academics_widgets.dart';

/// Semesters management: list every semester, add a new one, edit an existing.
class SemestersTab extends ConsumerWidget {
  const SemestersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(semestersProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Terms',
                  style: AppTypography.subtitle.copyWith(color: c.textPrimary),
                ),
              ),
              AppButton.secondary(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: () => refreshSemesters(ref),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: 'Add term',
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
                title: 'Couldn\'t load terms',
                subtitle: e.toString().replaceFirst('ApiException: ', ''),
                action: AppButton.secondary(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: () => refreshSemesters(ref),
                ),
              ),
              data: (semesters) {
                if (semesters.isEmpty) {
                  return const AcademicsEmpty(
                    icon: Icons.calendar_month_rounded,
                    title: 'No terms yet',
                    subtitle: 'Add a term to define your academic terms.',
                  );
                }
                return AcademicsListCard(
                  itemCount: semesters.length,
                  itemBuilder: (context, i) =>
                      _row(context, ref, c, semesters[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(
      BuildContext context, WidgetRef ref, AppColors c, SemesterSummary s) {
    return AcademicsRow(
      leadingIcon: Icons.calendar_month_rounded,
      title: s.semesterName,
      subtitle: 'Academic year ${s.academicYear}',
      trailing: AppBadge(label: s.academicYear, intent: BadgeIntent.brand),
      onTap: () => _openEditor(context, ref, s.semesterId),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, String? semesterId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SemesterEditor(semesterId: semesterId),
    );
  }
}

/// Add (semesterId == null) or edit (semesterId != null) a semester.
class _SemesterEditor extends ConsumerStatefulWidget {
  final String? semesterId;
  const _SemesterEditor({required this.semesterId});

  @override
  ConsumerState<_SemesterEditor> createState() => _SemesterEditorState();
}

class _SemesterEditorState extends ConsumerState<_SemesterEditor> {
  final _name = TextEditingController();
  final _year = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.semesterId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ref
          .read(academicsRepositoryProvider)
          .findSemester(widget.semesterId!);
      _name.text = d.semesterName;
      _year.text = d.academicYear;
      _start = _parse(d.semesterStartDate);
      _end = _parse(d.semesterEndDate);
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load terms.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Term name is required.');
      return;
    }
    if (_year.text.trim().isEmpty) {
      setState(() => _error = 'Academic year is required.');
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

    final repo = ref.read(academicsRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateSemester(SemesterDetail(
          semesterID: widget.semesterId!,
          semesterName: _name.text.trim(),
          semesterStartDate: _iso(_start!),
          semesterEndDate: _iso(_end!),
          academicYear: _year.text.trim(),
        ));
      } else {
        await repo.addSemester(NewSemesterRequest(
          semesterName: _name.text.trim(),
          startDate: _iso(_start!),
          endDate: _iso(_end!),
          academicYear: _year.text.trim(),
        ));
      }
      if (!mounted) return;
      await refreshSemesters(ref);
      if (!mounted) return;
      notify(ref, context,
          action: _isEdit ? 'Update term' : 'Add term',
          message: _isEdit ? 'Term updated.' : 'Term added.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: _isEdit ? 'Update term' : 'Add term', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not save. Try again.';
      notify(ref, context,
          action: _isEdit ? 'Update term' : 'Add term', message: msg,
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
    return AcademicsSheet(
      title: _isEdit ? 'Edit term' : 'Add term',
      icon: Icons.calendar_month_rounded,
      child: _loading
          ? const SizedBox(
          height: 160, child: Center(child: CircularProgressIndicator()))
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              flex: 2,
              child: AppTextField(
                label: 'Term name',
                hint: 'e.g. First Term',
                controller: _name,
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: AppTextField(
                label: 'Academic year',
                hint: 'e.g. 2025/2026',
                controller: _year,
              ),
            ),
          ]),
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
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.lg),
            AcademicsInlineError(message: _error!),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(children: [
            const Spacer(),
            AppButton.ghost(
              label: 'Cancel',
              onPressed:
              _saving ? null : () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: _isEdit ? 'Save changes' : 'Add term',
              busy: _saving,
              onPressed: _save,
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
