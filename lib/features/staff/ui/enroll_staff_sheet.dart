import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/notification/notifications.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../data/staff_models.dart';
import '../data/staff_providers.dart';

/// Bottom sheet to enroll a new staff member via
/// `POST /auth/v1/enroll-new-staff`.
class EnrollStaffSheet extends ConsumerStatefulWidget {
  const EnrollStaffSheet({super.key});

  @override
  ConsumerState<EnrollStaffSheet> createState() => _EnrollStaffSheetState();
}

class _EnrollStaffSheetState extends ConsumerState<EnrollStaffSheet> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _institutionId = TextEditingController();
  final _password = TextEditingController();

  String? _gender;
  DateTime? _dob;
  final Set<String> _roles = {};
  bool _obscure = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Prefill institution from the signed-in session's organization name.
    // If your backend needs the numeric institution ID here rather than the
    // name, replace this with that value (see PHASE5_NOTES).
    final session = ref.read(sessionProvider);
    if (session != null) {
      _institutionId.text = session.organizationName;
    }
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _institutionId.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_firstName.text.trim().isEmpty) return 'First name is required.';
    if (_lastName.text.trim().isEmpty) return 'Last name is required.';
    if (_gender == null) return 'Select a gender.';
    if (_dob == null) return 'Select a date of birth.';
    if (_email.text.trim().isEmpty) return 'Email is required.';
    if (_roles.isEmpty) return 'Assign at least one role.';
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
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

    final req = NewStaffRequest(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      gender: _gender!,
      dateOfBirth: _isoDate(_dob!),
      email: _email.text.trim(),
      phoneNumber: _phone.text.trim(),
      institutionId: _institutionId.text.trim(),
      password: _password.text,
      roles: _roles.toList(),
    );

    try {
      await ref.read(staffRepositoryProvider).enrollStaff(req);
      if (!mounted) return;
      ref.invalidate(staffRosterProvider);
      notify(ref, context,
          action: 'Enroll staff',
          message: '${req.firstName} ${req.lastName} enrolled.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      notify(ref, context,
          action: 'Enroll staff', message: e.message,
          isError: true, showSnackbar: false);
      setState(() {
        _saving = false;
        _error = e.message;
      });
    } catch (_) {
      const msg = 'Could not enroll staff. Try again.';
      notify(ref, context,
          action: 'Enroll staff', message: msg,
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
                  Row(children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: c.infoSubtle,
                        borderRadius: const BorderRadius.all(AppRadius.lgR),
                      ),
                      child: Icon(Icons.person_add_alt_1_rounded,
                          color: c.info, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enroll new staff',
                              style: AppTypography.title
                                  .copyWith(color: c.textPrimary)),
                          Text('Create a staff account and assign roles.',
                              style: AppTypography.caption
                                  .copyWith(color: c.textSecondary)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.xl),

                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: AppTextField(label: 'First name', hint: 'e.g. Kwame', controller: _firstName)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: AppTextField(label: 'Last name', hint: 'e.g. Mensah', controller: _lastName)),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: _genderDropdown(c)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: _dobPicker(c)),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: AppTextField(label: 'Email', hint: 'name@school.edu', controller: _email)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(child: AppTextField(label: 'Phone', hint: 'e.g. 024 123 4567', controller: _phone)),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: AppTextField(label: 'Institution', controller: _institutionId, enabled: false)),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: AppTextField(
                        label: 'Temporary password',
                        hint: 'At least 6 characters',
                        controller: _password,
                        obscureText: _obscure,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                            color: c.textMuted,
                          ),
                          splashRadius: 18,
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Roles',
                      style: AppTypography.label.copyWith(color: c.textSecondary)),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [for (final r in StaffRoles.all) _roleChip(c, r)],
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
                      onPressed:
                      _saving ? null : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton.primary(
                      label: 'Enroll staff',
                      busy: _saving,
                      onPressed: _submit,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ),
      ),
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
            Icon(selected ? Icons.check_rounded : Icons.add_rounded,
                size: 14, color: selected ? c.onBrand : c.textSecondary),
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
              initialDate: _dob ?? DateTime(now.year - 25),
              firstDate: DateTime(now.year - 70),
              lastDate: DateTime(now.year - 16),
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

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}