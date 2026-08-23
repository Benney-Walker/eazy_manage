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
import '../data/student_models.dart';
import '../data/student_providers.dart';

/// A bottom sheet showing one student's details, with an edit mode that saves
/// via `PUT /student/v1/update-student-data`.
class StudentDetailSheet extends ConsumerStatefulWidget {
  final String studentId;
  const StudentDetailSheet({super.key, required this.studentId});

  @override
  ConsumerState<StudentDetailSheet> createState() => _StudentDetailSheetState();
}

class _StudentDetailSheetState extends ConsumerState<StudentDetailSheet> {
  bool _editing = false;
  bool _saving = false;
  String? _error;

  // Editable field controllers, populated when entering edit mode.
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _parentName = TextEditingController();
  final _parentPhone = TextEditingController();
  final _homeTown = TextEditingController();
  final _dob = TextEditingController();
  String _gender = '';
  String _status = '';
  String _gradeId = '';

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _parentName.dispose();
    _parentPhone.dispose();
    _homeTown.dispose();
    _dob.dispose();
    super.dispose();
  }

  void _enterEdit(StudentDetail d) {
    _firstName.text = d.firstName;
    _lastName.text = d.lastName;
    _parentName.text = d.parentName;
    _parentPhone.text = d.parentPhoneNumber;
    _homeTown.text = d.homeTown;
    _dob.text = d.dateOfBirth;
    _gender = d.gender;
    _status = d.status;
    _gradeId = d.gradeId;
    setState(() {
      _editing = true;
      _error = null;
    });
  }

  Future<void> _save(StudentDetail original) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final updated = original.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      parentName: _parentName.text.trim(),
      parentPhoneNumber: _parentPhone.text.trim(),
      homeTown: _homeTown.text.trim(),
      dateOfBirth: _dob.text.trim(),
      gender: _gender,
      status: _status,
      gradeId: _gradeId,
    );

    try {
      await ref.read(studentRepositoryProvider).updateStudent(updated);
      if (!mounted) return;
      // Refresh detail + roster so the change shows immediately.
      ref.invalidate(studentDetailProvider(widget.studentId));
      ref.invalidate(rosterProvider);
      setState(() {
        _saving = false;
        _editing = false;
      });
      if (mounted) {
        notify(ref, context,
            action: 'Update student', message: 'Student updated.');
      }
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Update student', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not save changes. Try again.';
      notify(ref, context,
          action: 'Update student', message: msg,
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
    final detailAsync = ref.watch(studentDetailProvider(widget.studentId));

    return _sheetShell(
      c,
      child: detailAsync.when(
        loading: () => SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator(color: c.brand)),
        ),
        error: (e, _) => _errorBody(c, e.toString()),
        data: (d) => _editing ? _editBody(c, d) : _viewBody(c, d),
      ),
    );
  }

  // ---- View mode ----------------------------------------------------------
  Widget _viewBody(AppColors c, StudentDetail d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(c, d),
        const SizedBox(height: AppSpacing.xl),
        _fieldGrid(c, [
          _FieldPair('First name', d.firstName),
          _FieldPair('Last name', d.lastName),
          _FieldPair('Gender', d.gender),
          _FieldPair('Date of birth', d.dateOfBirth),
          _FieldPair('Home town', d.homeTown),
          _FieldPair('Status', d.status),
          _FieldPair('Parent / Guardian', d.parentName),
          _FieldPair('Guardian contact', d.parentPhoneNumber),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Spacer(),
            AppButton.ghost(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Edit details',
              icon: Icons.edit_rounded,
              onPressed: () => _enterEdit(d),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Edit mode ----------------------------------------------------------
  Widget _editBody(AppColors c, StudentDetail d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(c, d),
        const SizedBox(height: AppSpacing.xl),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: AppTextField(label: 'First name', controller: _firstName)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: AppTextField(label: 'Last name', controller: _lastName)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _genderDropdown(c)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: AppTextField(label: 'Date of birth (YYYY-MM-DD)', controller: _dob)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: AppTextField(label: 'Home town', controller: _homeTown)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: _statusDropdown(c)),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: AppTextField(label: 'Parent / Guardian', controller: _parentName)),
            const SizedBox(width: AppSpacing.lg),
            Expanded(child: AppTextField(label: 'Guardian contact', controller: _parentPhone)),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _inlineError(c, _error!),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            const Spacer(),
            AppButton.ghost(
              label: 'Cancel',
              onPressed: _saving ? null : () => setState(() => _editing = false),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Save changes',
              busy: _saving,
              onPressed: () => _save(d),
            ),
          ],
        ),
      ],
    );
  }

  Widget _genderDropdown(AppColors c) {
    return _labeledDropdown(
      c,
      label: 'Gender',
      value: _gender.isEmpty ? null : _gender,
      options: const ['MALE', 'FEMALE'],
      onChanged: (v) => setState(() => _gender = v ?? ''),
    );
  }

  Widget _statusDropdown(AppColors c) {
    return _labeledDropdown(
      c,
      label: 'Status',
      value: _status.isEmpty ? null : _status,
      options: const ['ACTIVE', 'INACTIVE', 'GRADUATED', 'WITHDRAWN'],
      onChanged: (v) => setState(() => _status = v ?? ''),
    );
  }

  // ---- Shared bits --------------------------------------------------------
  Widget _header(AppColors c, StudentDetail d) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.brand50,
            borderRadius: const BorderRadius.all(AppRadius.lgR),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(d.fullName),
            style: AppTypography.subtitle.copyWith(
              color: c.brand700,
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
                d.fullName.isEmpty ? 'Student' : d.fullName,
                style: AppTypography.title.copyWith(color: c.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(d.studentId,
                      style: AppTypography.caption.copyWith(color: c.textSecondary)),
                  if (d.status.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(
                      label: d.status,
                      intent: d.status.toUpperCase() == 'ACTIVE'
                          ? BadgeIntent.success
                          : BadgeIntent.neutral,
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fieldGrid(AppColors c, List<_FieldPair> pairs) {
    return Wrap(
      spacing: AppSpacing.xxl,
      runSpacing: AppSpacing.lg,
      children: [
        for (final p in pairs)
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.label,
                    style: AppTypography.caption.copyWith(color: c.textMuted)),
                const SizedBox(height: 2),
                Text(
                  p.value.isEmpty ? '—' : p.value,
                  style: AppTypography.body.copyWith(color: c.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _labeledDropdown(
      AppColors c, {
        required String label,
        required String? value,
        required List<String> options,
        required ValueChanged<String?> onChanged,
      }) {
    // Keep the current value visible even if it isn't in the option list.
    final items = {...options, if (value != null) value}.toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppTypography.label.copyWith(color: c.textSecondary)),
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
              value: value,
              isExpanded: true,
              hint: Text('Select',
                  style: AppTypography.body.copyWith(color: c.inputPlaceholder)),
              icon: Icon(Icons.expand_more_rounded, color: c.textSecondary),
              dropdownColor: c.surfaceElevated,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              items: [
                for (final o in items)
                  DropdownMenuItem(
                    value: o,
                    child: Text(o,
                        style: AppTypography.body.copyWith(color: c.textPrimary)),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _inlineError(AppColors c, String msg) {
    return Container(
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
            child: Text(msg,
                style: AppTypography.caption.copyWith(color: c.danger)),
          ),
        ],
      ),
    );
  }

  Widget _errorBody(AppColors c, String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 32, color: c.danger),
          const SizedBox(height: AppSpacing.md),
          Text('Couldn\'t load this student',
              style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message.replaceFirst('ApiException: ', ''),
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(color: c.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton.secondary(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _sheetShell(AppColors c, {required Widget child}) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
    name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }
}

class _FieldPair {
  final String label;
  final String value;
  const _FieldPair(this.label, this.value);
}