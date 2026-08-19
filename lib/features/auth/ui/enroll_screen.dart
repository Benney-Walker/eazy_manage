import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_scaffold.dart';

/// Enrollment form. Reached only via subscription, so the institution id is
/// prefilled + locked and the role is locked to Principal (matching JavaFX).
class EnrollScreen extends ConsumerStatefulWidget {
  final String institutionId;
  const EnrollScreen({super.key, required this.institutionId});

  @override
  ConsumerState<EnrollScreen> createState() => _EnrollScreenState();
}

class _EnrollScreenState extends ConsumerState<EnrollScreen> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  late final _institutionCtrl =
  TextEditingController(text: widget.institutionId);
  final _roleCtrl = TextEditingController(text: 'Principal');

  String? _gender; // MALE / FEMALE
  DateTime? _dob;
  bool _busy = false;
  String? _error;
  String? _staffId; // set on success

  static final _emailRe = RegExp(r'^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+\.[A-Za-z]+$');

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    _institutionCtrl.dispose();
    _roleCtrl.dispose();
    super.dispose();
  }

  String? _validate() {
    if (_firstName.text.trim().isEmpty) return 'Enter the first name.';
    if (_lastName.text.trim().isEmpty) return 'Enter the last name.';
    if (_gender == null) return 'Select a gender.';
    if (_dob == null) return 'Select a date of birth.';
    if (!_emailRe.hasMatch(_email.text.trim())) {
      return 'Enter a valid email address.';
    }
    if (_phone.text.trim().isEmpty) return 'Enter a phone number.';
    if (_password.text.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    if (_password.text != _confirm.text) return 'Passwords do not match.';
    return null;
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final staffId = await ref.read(authRepositoryProvider).enrollStaff(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        gender: _gender!,
        dateOfBirth: DateFormat('yyyy-MM-dd').format(_dob!),
        email: _email.text.trim(),
        phoneNumber: _phone.text.trim(),
        institutionId: widget.institutionId,
        password: _password.text,
        roles: const ['PRINCIPAL'],
      );
      if (!mounted) return;
      setState(() {
        _busy = false;
        _staffId = staffId;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Couldn\'t enroll. Please try again.';
      });
    }
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 30),
      firstDate: DateTime(1940),
      lastDate: now,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    if (_staffId != null) {
      return AuthScaffold(
        title: 'Principal enrolled',
        subtitle: 'Share this Staff ID — it\'s used to sign in.',
        children: _successBody(c),
      );
    }

    return AuthScaffold(
      title: 'Enroll principal',
      subtitle: 'Create the principal account for this institution.',
      children: [
        Row(children: [
          Expanded(child: AppTextField(label: 'First name', controller: _firstName)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: AppTextField(label: 'Last name', controller: _lastName)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(child: _genderField(c)),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: _dobField(c)),
        ]),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
          label: 'Phone number',
          controller: _phone,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(children: [
          Expanded(
            child: AppTextField(
              label: 'Institution ID',
              controller: _institutionCtrl,
              enabled: false,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppTextField(
              label: 'Role',
              controller: _roleCtrl,
              enabled: false,
            ),
          ),
        ]),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(label: 'Password', controller: _password, obscureText: true),
        const SizedBox(height: AppSpacing.lg),
        AppTextField(
            label: 'Confirm password', controller: _confirm, obscureText: true),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.lg),
          AuthError(message: _error!),
        ],
        const SizedBox(height: AppSpacing.xl),
        AppButton.primary(
          label: 'Enroll principal',
          expand: true,
          busy: _busy,
          onPressed: _submit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: TextButton(
            onPressed: _busy ? null : () => context.go('/auth'),
            child: Text('← Back to login',
                style: AppTypography.button.copyWith(color: c.textSecondary)),
          ),
        ),
      ],
    );
  }

  Widget _genderField(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Gender',
            style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<String>(
          value: _gender,
          decoration: InputDecoration(
            hintText: 'Select',
            filled: true,
            fillColor: c.inputBg,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            border: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              borderSide: BorderSide(color: c.inputBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              borderSide: BorderSide(color: c.inputBorder),
            ),
          ),
          items: const [
            DropdownMenuItem(value: 'MALE', child: Text('Male')),
            DropdownMenuItem(value: 'FEMALE', child: Text('Female')),
          ],
          onChanged: _busy ? null : (v) => setState(() => _gender = v),
        ),
      ],
    );
  }

  Widget _dobField(AppColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Date of birth',
            style: AppTypography.label.copyWith(color: c.textSecondary)),
        const SizedBox(height: AppSpacing.sm),
        InkWell(
          onTap: _busy ? null : _pickDob,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: c.inputBg,
              borderRadius: const BorderRadius.all(AppRadius.mdR),
              border: Border.all(color: c.inputBorder),
            ),
            alignment: Alignment.centerLeft,
            child: Row(children: [
              Icon(Icons.calendar_today_rounded, size: 16, color: c.textMuted),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _dob == null
                    ? 'Select date'
                    : DateFormat('yyyy-MM-dd').format(_dob!),
                style: AppTypography.body.copyWith(
                    color: _dob == null ? c.inputPlaceholder : c.textPrimary),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  List<Widget> _successBody(AppColors c) {
    return [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: c.successSubtle,
          borderRadius: const BorderRadius.all(AppRadius.mdR),
          border: Border.all(color: c.success, width: AppStroke.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Staff ID',
                style: AppTypography.label.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(_staffId!,
                style: AppTypography.subtitle.copyWith(color: c.textPrimary)),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton.primary(
        label: 'Go to login',
        expand: true,
        onPressed: () => context.go('/auth'),
      ),
    ];
  }
}
