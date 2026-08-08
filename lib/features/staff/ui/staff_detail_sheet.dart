import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_badge.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/staff_models.dart';
import '../data/staff_providers.dart';

/// Bottom sheet for one staff member: view details, edit them (including
/// multi-role assignment + status), or reset their password.
class StaffDetailSheet extends ConsumerStatefulWidget {
  final String staffId;
  const StaffDetailSheet({super.key, required this.staffId});

  @override
  ConsumerState<StaffDetailSheet> createState() => _StaffDetailSheetState();
}

enum _Mode { view, edit, resetPassword }

class _StaffDetailSheetState extends ConsumerState<StaffDetailSheet> {
  _Mode _mode = _Mode.view;
  bool _saving = false;
  String? _error;

  // Edit controllers
  final _firstName = TextEditingController();
  final _surname = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _dob = TextEditingController();
  String _gender = '';
  String _status = '';
  final Set<String> _roles = {};

  // Password reset controllers
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _firstName.dispose();
    _surname.dispose();
    _email.dispose();
    _phone.dispose();
    _dob.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  void _enterEdit(StaffDetail d) {
    _firstName.text = d.firstName;
    _surname.text = d.surname;
    _email.text = d.email;
    _phone.text = d.phoneNumber;
    _dob.text = d.dateOfBirth;
    _gender = d.gender;
    _status = d.staffStatus;
    _roles
      ..clear()
      ..addAll(d.staffRoles);
    setState(() {
      _mode = _Mode.edit;
      _error = null;
    });
  }

  Future<void> _saveEdit(StaffDetail original) async {
    if (_roles.isEmpty) {
      setState(() => _error = 'Assign at least one role.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final updated = original.copyWith(
      firstName: _firstName.text.trim(),
      surname: _surname.text.trim(),
      email: _email.text.trim(),
      phoneNumber: _phone.text.trim(),
      dateOfBirth: _dob.text.trim(),
      gender: _gender,
      staffStatus: _status,
      staffRoles: _roles.toList(),
    );

    try {
      await ref.read(staffRepositoryProvider).updateStaff(updated);
      if (!mounted) return;
      ref.invalidate(staffDetailProvider(widget.staffId));
      ref.invalidate(staffRosterProvider);
      setState(() {
        _saving = false;
        _mode = _Mode.view;
      });
      _toast('Staff updated.');
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Could not save changes. Try again.';
      });
    }
  }

  Future<void> _resetPassword() async {
    final pw = _newPassword.text;
    final confirm = _confirmPassword.text;
    if (pw.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (pw != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(staffRepositoryProvider).resetPassword(
            targetStaffId: widget.staffId,
            newPassword: pw,
          );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _mode = _Mode.view;
      });
      _newPassword.clear();
      _confirmPassword.clear();
      _toast('Password reset.');
    } on ApiException catch (e) {
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      setState(() {
        _saving = false;
        _error = 'Could not reset password. Try again.';
      });
    }
  }

  void _toast(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final detailAsync = ref.watch(staffDetailProvider(widget.staffId));

    return _shell(
      c,
      child: detailAsync.when(
        loading: () => const SizedBox(
          height: 240,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => _errorBody(c, e.toString()),
        data: (d) => switch (_mode) {
          _Mode.view => _viewBody(c, d),
          _Mode.edit => _editBody(c, d),
          _Mode.resetPassword => _resetBody(c, d),
        },
      ),
    );
  }

  // ---- View ---------------------------------------------------------------
  Widget _viewBody(AppColors c, StaffDetail d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(c, d),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final r in d.staffRoles)
              AppBadge(label: StaffRoles.label(r), intent: BadgeIntent.brand),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        _fieldGrid(c, [
          _FieldPair('First name', d.firstName),
          _FieldPair('Surname', d.surname),
          _FieldPair('Gender', d.gender),
          _FieldPair('Date of birth', d.dateOfBirth),
          _FieldPair('Email', d.email),
          _FieldPair('Phone', d.phoneNumber),
          _FieldPair('Status', d.staffStatus),
          _FieldPair('Registered', d.dateOfRegistration),
        ]),
        const SizedBox(height: AppSpacing.xl),
        Row(
          children: [
            AppButton.secondary(
              label: 'Reset password',
              icon: Icons.lock_reset_rounded,
              onPressed: () => setState(() {
                _mode = _Mode.resetPassword;
                _error = null;
              }),
            ),
            const Spacer(),
            AppButton.ghost(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
            const SizedBox(width: AppSpacing.sm),
            AppButton.primary(
              label: 'Edit',
              icon: Icons.edit_rounded,
              onPressed: () => _enterEdit(d),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Edit ---------------------------------------------------------------
  Widget _editBody(AppColors c, StaffDetail d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(c, d),
        const SizedBox(height: AppSpacing.xl),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: AppTextField(label: 'First name', controller: _firstName)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: AppTextField(label: 'Surname', controller: _surname)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _dropdown(c, 'Gender', _gender, const ['MALE', 'FEMALE'],
              (v) => setState(() => _gender = v ?? ''))),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: AppTextField(label: 'Date of birth (YYYY-MM-DD)', controller: _dob)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: AppTextField(label: 'Email', controller: _email)),
          const SizedBox(width: AppSpacing.lg),
          Expanded(child: AppTextField(label: 'Phone', controller: _phone)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        _dropdown(c, 'Status', _status, StaffStatus.all,
            (v) => setState(() => _status = v ?? '')),
        const SizedBox(height: AppSpacing.lg),
        Text('Roles', style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final r in StaffRoles.all) _roleChip(c, r),
          ],
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _inlineError(c, _error!),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(children: [
          const Spacer(),
          AppButton.ghost(
            label: 'Cancel',
            onPressed: _saving ? null : () => setState(() => _mode = _Mode.view),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton.primary(
            label: 'Save changes',
            busy: _saving,
            onPressed: () => _saveEdit(d),
          ),
        ]),
      ],
    );
  }

  Widget _roleChip(AppColors c, String role) {
    final selected = _roles.contains(role);
    return GestureDetector(
      onTap: () => setState(() {
        if (selected) {
          _roles.remove(role);
        } else {
          _roles.add(role);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: selected ? c.brand : c.surfaceAlt,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          border: Border.all(
            color: selected ? c.brand : c.border,
            width: AppStroke.hairline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : Icons.add_rounded,
              size: 14,
              color: selected ? c.onBrand : c.textSecondary,
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              StaffRoles.label(role),
              style: AppTypography.caption.copyWith(
                color: selected ? c.onBrand : c.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Reset password -----------------------------------------------------
  Widget _resetBody(AppColors c, StaffDetail d) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _header(c, d),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: c.warningSubtle,
            borderRadius: const BorderRadius.all(AppRadius.mdR),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 16, color: c.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'You are resetting the password for ${d.fullName} (${d.staffId}).',
                  style: AppTypography.caption.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'New password',
          controller: _newPassword,
          obscureText: _obscure,
          hint: 'At least 6 characters',
          suffixIcon: IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(
              _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              size: 18,
              color: c.textMuted,
            ),
            splashRadius: 18,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Confirm password',
          controller: _confirmPassword,
          obscureText: _obscure,
          hint: 'Re-enter the password',
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _inlineError(c, _error!),
        ],
        const SizedBox(height: AppSpacing.xl),
        Row(children: [
          const Spacer(),
          AppButton.ghost(
            label: 'Cancel',
            onPressed: _saving ? null : () => setState(() => _mode = _Mode.view),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppButton.primary(
            label: 'Reset password',
            busy: _saving,
            onPressed: _resetPassword,
          ),
        ]),
      ],
    );
  }

  // ---- Shared -------------------------------------------------------------
  Widget _header(AppColors c, StaffDetail d) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: c.infoSubtle,
            borderRadius: const BorderRadius.all(AppRadius.lgR),
          ),
          alignment: Alignment.center,
          child: Text(
            _initials(d.fullName),
            style: AppTypography.subtitle.copyWith(
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
                d.fullName.isEmpty ? 'Staff' : d.fullName,
                style: AppTypography.title.copyWith(color: c.textPrimary),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(d.staffId,
                      style: AppTypography.caption.copyWith(color: c.textSecondary)),
                  if (d.staffStatus.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.sm),
                    AppBadge(
                      label: d.staffStatus,
                      intent: d.staffStatus.toUpperCase() == 'ACTIVE'
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
                Text(p.value.isEmpty ? '—' : p.value,
                    style: AppTypography.body.copyWith(color: c.textPrimary)),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dropdown(AppColors c, String label, String value, List<String> options,
      ValueChanged<String?> onChanged) {
    final items = {...options, if (value.isNotEmpty) value}.toList();
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
              value: value.isEmpty ? null : value,
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
          Text('Couldn\'t load this staff member',
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

  Widget _shell(AppColors c, {required Widget child}) {
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
