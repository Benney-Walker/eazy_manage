import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../staff/data/staff_models.dart';
import '../../staff/data/staff_providers.dart';
import '../../students/data/student_providers.dart';
import '../data/academics_models.dart';
import '../data/academics_providers.dart';
import 'academics_widgets.dart';

/// Classes management: list every class, add a new one (name + instructor),
/// or edit an existing class's name and assigned instructor.
///
/// Reuses `classesProvider` (from Students) for the list and
/// `staffRosterProvider` (from Staff) for the instructor picker.
class ClassesTab extends ConsumerWidget {
  const ClassesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final async = ref.watch(classesProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Classes',
                    style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
              ),
              AppButton.secondary(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: () => ref.invalidate(classesProvider),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: 'Add class',
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
                title: 'Couldn\'t load classes',
                subtitle: e.toString().replaceFirst('ApiException: ', ''),
                action: AppButton.secondary(
                  label: 'Retry',
                  icon: Icons.refresh_rounded,
                  onPressed: () => ref.invalidate(classesProvider),
                ),
              ),
              data: (classes) {
                if (classes.isEmpty) {
                  return const AcademicsEmpty(
                    icon: Icons.class_rounded,
                    title: 'No classes yet',
                    subtitle: 'Add a class to start organizing students.',
                  );
                }
                return AcademicsListCard(
                  itemCount: classes.length,
                  itemBuilder: (context, i) {
                    final cls = classes[i];
                    return AcademicsRow(
                      leadingIcon: Icons.class_rounded,
                      title: cls.levelName,
                      subtitle: cls.levelId,
                      onTap: () => _openEditor(context, ref, cls.levelId),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, String? levelId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClassEditor(levelId: levelId),
    );
  }
}

/// Add (levelId == null) or edit (levelId != null) a class.
class _ClassEditor extends ConsumerStatefulWidget {
  final String? levelId;
  const _ClassEditor({required this.levelId});

  @override
  ConsumerState<_ClassEditor> createState() => _ClassEditorState();
}

class _ClassEditorState extends ConsumerState<_ClassEditor> {
  final _name = TextEditingController();
  String? _instructorId;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.levelId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d =
          await ref.read(academicsRepositoryProvider).findClass(widget.levelId!);
      _name.text = d.levelName;
      _instructorId = d.staffId.isEmpty ? null : d.staffId;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load class.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Class name is required.');
      return;
    }
    if (_instructorId == null || _instructorId!.isEmpty) {
      setState(() => _error = 'Assign an instructor.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(academicsRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateClass(ClassDetail(
          levelId: widget.levelId!,
          levelName: _name.text.trim(),
          staffId: _instructorId!,
        ));
      } else {
        await repo.addClass(
          gradeName: _name.text.trim(),
          instructorId: _instructorId!,
        );
      }
      if (!mounted) return;
      ref.invalidate(classesProvider);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Class updated.' : 'Class added.')),
      );
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Could not save. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final staffAsync = ref.watch(staffRosterProvider);

    return AcademicsSheet(
      title: _isEdit ? 'Edit class' : 'Add class',
      icon: Icons.class_rounded,
      child: _loading
          ? const SizedBox(
              height: 160, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppTextField(
                  label: 'Class name',
                  hint: 'e.g. Basic 4',
                  controller: _name,
                ),
                const SizedBox(height: AppSpacing.lg),
                staffAsync.when(
                  loading: () => AcademicsDropdown<String>(
                    label: 'Instructor',
                    value: null,
                    items: const [],
                    onChanged: (_) {},
                    hint: 'Loading staff…',
                  ),
                  error: (_, __) => AcademicsDropdown<String>(
                    label: 'Instructor',
                    value: null,
                    items: const [],
                    onChanged: (_) {},
                    hint: 'Staff unavailable',
                  ),
                  data: (staff) {
                    final valid =
                        staff.any((s) => s.staffId == _instructorId)
                            ? _instructorId
                            : null;
                    return AcademicsDropdown<String>(
                      label: 'Instructor',
                      value: valid,
                      hint: 'Select instructor',
                      items: [
                        for (final StaffSummary s in staff)
                          DropdownMenuItem(
                            value: s.staffId,
                            child: Text(
                              s.staffName,
                              style: AppTypography.body
                                  .copyWith(color: c.textPrimary),
                            ),
                          ),
                      ],
                      onChanged: (v) => setState(() => _instructorId = v),
                    );
                  },
                ),
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
                    label: _isEdit ? 'Save changes' : 'Add class',
                    busy: _saving,
                    onPressed: _save,
                  ),
                ]),
              ],
            ),
    );
  }
}
