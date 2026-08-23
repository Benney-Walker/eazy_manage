import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../students/data/student_models.dart';
import '../../students/data/student_providers.dart';
import '../data/academics_models.dart';
import '../data/academics_providers.dart';
import 'academics_widgets.dart';

/// Subjects management, scoped to a class: pick a class, see its subjects,
/// add a new subject or edit an existing one.
///
/// Reuses `classesProvider` from the Students feature — the class list comes
/// from the same `GET /staff/v1/load-classes` endpoint, so there's no reason
/// to fetch it twice.
class SubjectsTab extends ConsumerWidget {
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = AppColors.of(context);
    final classesAsync = ref.watch(classesProvider);
    final selectedLevelId = ref.watch(subjectsClassProvider);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 260,
                child: classesAsync.when(
                  loading: () => AcademicsDropdown<String>(
                    label: 'Class',
                    value: null,
                    items: const [],
                    onChanged: (_) {},
                    hint: 'Loading classes…',
                  ),
                  error: (_, __) => AcademicsDropdown<String>(
                    label: 'Class',
                    value: null,
                    items: const [],
                    onChanged: (_) {},
                    hint: 'Classes unavailable',
                  ),
                  data: (classes) => AcademicsDropdown<String>(
                    label: 'Class',
                    value: _validValue(selectedLevelId, classes),
                    hint: 'Select class',
                    items: [
                      for (final cls in classes)
                        DropdownMenuItem(
                          value: cls.levelId,
                          child: Text(
                            cls.levelName,
                            style: AppTypography.body
                                .copyWith(color: c.textPrimary),
                          ),
                        ),
                    ],
                    onChanged: (v) =>
                    ref.read(subjectsClassProvider.notifier).state = v,
                  ),
                ),
              ),
              const Spacer(),
              AppButton.secondary(
                label: 'Refresh',
                icon: Icons.refresh_rounded,
                onPressed: selectedLevelId == null
                    ? null
                    : () => ref.invalidate(subjectsProvider),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppButton.primary(
                label: 'Add subject',
                icon: Icons.add_rounded,
                onPressed: () => _openEditor(context, ref, null),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(child: _body(context, ref, c, selectedLevelId)),
        ],
      ),
    );
  }

  /// Guard against a stale selection that isn't in the loaded class list.
  String? _validValue(String? selected, List<ClassOption> classes) {
    if (selected == null) return null;
    return classes.any((c) => c.levelId == selected) ? selected : null;
  }

  Widget _body(
      BuildContext context, WidgetRef ref, AppColors c, String? selectedLevelId) {
    if (selectedLevelId == null) {
      return const AcademicsEmpty(
        icon: Icons.menu_book_rounded,
        title: 'Choose a class',
        subtitle: 'Pick a class to see and manage the subjects offered in it.',
      );
    }

    final async = ref.watch(subjectsProvider);
    return async.when(
      loading: () => Center(child: CircularProgressIndicator(color: c.brand)),
      error: (e, _) => AcademicsEmpty(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load subjects',
        subtitle: e.toString().replaceFirst('ApiException: ', ''),
        action: AppButton.secondary(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onPressed: () => ref.invalidate(subjectsProvider),
        ),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return const AcademicsEmpty(
            icon: Icons.menu_book_rounded,
            title: 'No subjects for this class',
            subtitle: 'Add a subject to start building the class curriculum.',
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                  bottom: AppSpacing.sm, left: AppSpacing.xs),
              child: Text(
                '${subjects.length} subject${subjects.length == 1 ? '' : 's'}',
                style: AppTypography.caption.copyWith(color: c.textSecondary),
              ),
            ),
            Expanded(
              child: AcademicsListCard(
                itemCount: subjects.length,
                itemBuilder: (context, i) {
                  final s = subjects[i];
                  return AcademicsRow(
                    leadingIcon: Icons.menu_book_rounded,
                    title: s.subjectName,
                    subtitle: s.subjectId,
                    onTap: () => _openEditor(context, ref, s.subjectId),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _openEditor(BuildContext context, WidgetRef ref, String? subjectId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SubjectEditor(subjectId: subjectId),
    );
  }
}

/// Add (subjectId == null) or edit (subjectId != null) a subject.
class _SubjectEditor extends ConsumerStatefulWidget {
  final String? subjectId;
  const _SubjectEditor({required this.subjectId});

  @override
  ConsumerState<_SubjectEditor> createState() => _SubjectEditorState();
}

class _SubjectEditorState extends ConsumerState<_SubjectEditor> {
  final _name = TextEditingController();
  String? _levelId;

  bool _loading = false;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.subjectId != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _load();
    } else {
      // Default the class to whatever the tab is currently showing.
      _levelId = ref.read(subjectsClassProvider);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await ref
          .read(academicsRepositoryProvider)
          .findSubject(widget.subjectId!);
      _name.text = d.subjectName;
      _levelId = d.levelId.isEmpty ? ref.read(subjectsClassProvider) : d.levelId;
    } on ApiException catch (e) {
      _error = e.message;
    } catch (_) {
      _error = 'Could not load subject.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _error = 'Subject name is required.');
      return;
    }
    if (_levelId == null || _levelId!.isEmpty) {
      setState(() => _error = 'Select a class.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(academicsRepositoryProvider);
    try {
      if (_isEdit) {
        await repo.updateSubject(SubjectDetail(
          subjectId: widget.subjectId!,
          subjectName: _name.text.trim(),
          levelId: _levelId!,
        ));
      } else {
        await repo.addSubject(NewSubjectRequest(
          subjectName: _name.text.trim(),
          gradeId: _levelId!,
        ));
      }
      if (!mounted) return;
      ref.invalidate(subjectsProvider);
      notify(ref, context,
          action: _isEdit ? 'Update subject' : 'Add subject',
          message: _isEdit ? 'Subject updated.' : 'Subject added.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: _isEdit ? 'Update subject' : 'Add subject', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not save. Try again.';
      notify(ref, context,
          action: _isEdit ? 'Update subject' : 'Add subject', message: msg,
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
    final classesAsync = ref.watch(classesProvider);

    return AcademicsSheet(
      title: _isEdit ? 'Edit subject' : 'Add subject',
      icon: Icons.menu_book_rounded,
      child: _loading
          ? const SizedBox(
          height: 160, child: Center(child: CircularProgressIndicator()))
          : Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Subject name',
            hint: 'e.g. Integrated Science',
            controller: _name,
          ),
          const SizedBox(height: AppSpacing.lg),
          classesAsync.when(
            loading: () => AcademicsDropdown<String>(
              label: 'Class',
              value: null,
              items: const [],
              onChanged: (_) {},
              hint: 'Loading classes…',
            ),
            error: (_, __) => AcademicsDropdown<String>(
              label: 'Class',
              value: null,
              items: const [],
              onChanged: (_) {},
              hint: 'Classes unavailable',
            ),
            data: (classes) {
              final valid = classes.any((cl) => cl.levelId == _levelId)
                  ? _levelId
                  : null;
              return AcademicsDropdown<String>(
                label: 'Class',
                value: valid,
                hint: 'Select class',
                items: [
                  for (final cls in classes)
                    DropdownMenuItem(
                      value: cls.levelId,
                      child: Text(
                        cls.levelName,
                        style: AppTypography.body
                            .copyWith(color: c.textPrimary),
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _levelId = v),
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
              label: _isEdit ? 'Save changes' : 'Add subject',
              busy: _saving,
              onPressed: _save,
            ),
          ]),
        ],
      ),
    );
  }
}
