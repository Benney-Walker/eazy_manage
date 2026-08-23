import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/student_models.dart';
import '../data/student_providers.dart';

/// A bottom sheet form to enroll a new student via
/// `POST /student/v1/add-new-student`.
class AddStudentSheet extends ConsumerStatefulWidget {
  const AddStudentSheet({super.key});

  @override
  ConsumerState<AddStudentSheet> createState() => _AddStudentSheetState();
}

class _AddStudentSheetState extends ConsumerState<AddStudentSheet> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _homeTown = TextEditingController();
  final _parentName = TextEditingController();
  final _guardianContact = TextEditingController();

  ClassOption? _class;
  String? _gender;
  DateTime? _dob;

  bool _saving = false;
  bool _isNew = false;
  String? _error;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _homeTown.dispose();
    _parentName.dispose();
    _guardianContact.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_firstName.text.trim().isEmpty) return 'First name is required.';
    if (_lastName.text.trim().isEmpty) return 'Last name is required.';
    if (_class == null) return 'Select a class.';
    if (_gender == null) return 'Select a gender.';
    if (_dob == null) return 'Select a date of birth.';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final req = NewStudentRequest(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      levelId: _class!.levelId,
      gender: _gender!,
      dateOfBirth: _isoDate(_dob!),
      hometown: _homeTown.text.trim(),
      parentName: _parentName.text.trim(),
      guardianContact: _guardianContact.text.trim(),
      isNew: _isNew,
    );

    try {
      await ref.read(studentRepositoryProvider).addStudent(req);
      if (!mounted) return;
      // If the new student is in the currently-viewed class, refresh the roster.
      final selected = ref.read(selectedClassProvider);
      if (selected?.levelId == _class!.levelId) {
        ref.invalidate(rosterProvider);
      }
      notify(ref, context,
          action: 'Enroll student',
          message: '${req.firstName} ${req.lastName} enrolled.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Enroll student', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not enroll student. Try again.';
      notify(ref, context,
          action: 'Enroll student', message: msg,
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

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Container(
            margin: const EdgeInsets.all(AppSpacing.lg),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: const BorderRadius.all(AppRadius.xlR),
              border: Border.all(color: c.border, width: AppStroke.hairline),
              boxShadow: [
                BoxShadow(color: c.shadow, blurRadius: 32, offset: const Offset(0, 12)),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: c.brand50,
                          borderRadius: const BorderRadius.all(AppRadius.lgR),
                        ),
                        child: Icon(Icons.person_add_alt_1_rounded,
                            color: c.brand, size: 22),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Enroll new student',
                                style: AppTypography.title
                                    .copyWith(color: c.textPrimary)),
                            Text('Fill in the student\'s details below.',
                                style: AppTypography.caption
                                    .copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: AppTextField(label: 'First name', hint: 'e.g. Ama', controller: _firstName)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: AppTextField(label: 'Last name', hint: 'e.g. Boateng', controller: _lastName)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _classDropdown(c, classesAsync)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: _genderDropdown(c)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _dobPicker(c)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: AppTextField(label: 'Home town', hint: 'e.g. Kumasi', controller: _homeTown)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: AppTextField(label: 'Parent / Guardian', hint: 'Full name', controller: _parentName)),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(child: AppTextField(label: 'Guardian contact', hint: 'e.g. 024 123 4567', controller: _guardianContact)),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.lg),
                  InkWell(
                    onTap: _saving ? null : () => setState(() => _isNew = !_isNew),
                    borderRadius: const BorderRadius.all(AppRadius.smR),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _isNew,
                              onChanged: _saving ? null : (v) => setState(() => _isNew = v ?? false),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text('New student',
                              style: AppTypography.body.copyWith(color: c.textPrimary)),
                        ],
                      ),
                    ),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: c.dangerSubtle,
                        borderRadius: const BorderRadius.all(AppRadius.mdR),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 16, color: c.danger),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(_error!,
                                style: AppTypography.caption.copyWith(color: c.danger)),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  Row(
                    children: [
                      const Spacer(),
                      AppButton.ghost(
                        label: 'Cancel',
                        onPressed: _saving ? null : () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton.primary(
                        label: 'Enroll student',
                        busy: _saving,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _classDropdown(AppColors c, AsyncValue<List<ClassOption>> classesAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Class', style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
          ),
          child: DropdownButtonHideUnderline(
            child: classesAsync.when(
              loading: () => Align(
                alignment: Alignment.centerLeft,
                child: Text('Loading…',
                    style: AppTypography.body.copyWith(color: c.textMuted)),
              ),
              error: (_, __) => Align(
                alignment: Alignment.centerLeft,
                child: Text('Unavailable',
                    style: AppTypography.body.copyWith(color: c.danger)),
              ),
              data: (classes) => DropdownButton<ClassOption>(
                value: _class,
                isExpanded: true,
                hint: Text('Select class',
                    style: AppTypography.body.copyWith(color: c.inputPlaceholder)),
                icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
                dropdownColor: c.surfaceElevated,
                borderRadius: const BorderRadius.all(AppRadius.mdR),
                items: [
                  for (final cls in classes)
                    DropdownMenuItem(
                      value: cls,
                      child: Text(cls.levelName,
                          style: AppTypography.body.copyWith(color: c.textPrimary)),
                    ),
                ],
                onChanged: (v) => setState(() => _class = v),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _genderDropdown(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Gender', style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: c.inputBg,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
            border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _gender,
              isExpanded: true,
              hint: Text('Select',
                  style: AppTypography.body.copyWith(color: c.inputPlaceholder)),
              icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
              dropdownColor: c.surfaceElevated,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              items: const [
                DropdownMenuItem(value: 'MALE', child: Text('Male')),
                DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
              ],
              onChanged: (v) => setState(() => _gender = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dobPicker(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Date of birth',
            style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.xs + 2),
        InkWell(
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          onTap: () async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(now.year - 6),
              firstDate: DateTime(now.year - 30),
              lastDate: now,
            );
            if (picked != null) setState(() => _dob = picked);
          },
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.inputBg,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              border: Border.all(color: c.inputBorder, width: AppStroke.hairline),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 16, color: c.textMuted),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  _dob == null ? 'Select date' : _isoDate(_dob!),
                  style: AppTypography.body.copyWith(
                    color: _dob == null ? c.inputPlaceholder : c.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}