import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/session/session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';

/// The sign-in screen: a split card with a gradient brand hero on the left and
/// the login form on the right — a modernized take on the JavaFX auth layout.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _staffIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _staffIdCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final staffId = _staffIdCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (staffId.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter your Staff ID and password.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    final err = await ref
        .read(authProvider.notifier)
        .login(staffId: staffId, password: password);

    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      setState(() => _error = err);
    }
    // On success the router redirect swaps us into the shell automatically.
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 920, maxHeight: 580),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.all(AppRadius.xlR),
                border: Border.all(color: c.border, width: AppStroke.hairline),
                boxShadow: [
                  BoxShadow(
                    color: c.shadow,
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.all(AppRadius.xlR),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _brandPanel(c),
                      Expanded(child: _formPanel(c)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- Left: gradient brand hero -----------------------------------------
  Widget _brandPanel(AppColors c) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          // ~160° gradient, matching the JavaFX login hero direction.
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.brand700, c.brand800],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: const BorderRadius.all(AppRadius.lgR),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'E',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'EazyManage',
            style: AppTypography.display.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'by Bynex Technologies',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Smart school management — records, attendance, results and finance in one place.',
            style: AppTypography.body.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
          const Spacer(),
          _feature(c, 'Secure student records'),
          const SizedBox(height: AppSpacing.md),
          _feature(c, 'Attendance & results'),
          const SizedBox(height: AppSpacing.md),
          _feature(c, 'Finance & analytics'),
        ],
      ),
    );
  }

  Widget _feature(AppColors c, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Icon(Icons.check_rounded, size: 13, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          label,
          style: AppTypography.body.copyWith(
            color: Colors.white.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }

  // ---- Right: login form --------------------------------------------------
  Widget _formPanel(AppColors c) {
    return Container(
      color: c.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.xxl,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back',
                  style: AppTypography.title.copyWith(color: c.textPrimary)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Sign in to your account to continue.',
                style: AppTypography.body.copyWith(color: c.textSecondary),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppTextField(
                label: 'Staff ID',
                hint: 'e.g. STF100200',
                controller: _staffIdCtrl,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.lg),

              AppTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: _passwordCtrl,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(),
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

              if (_error != null) ...[
                const SizedBox(height: AppSpacing.lg),
                _errorBanner(c, _error!),
              ],

              const SizedBox(height: AppSpacing.xl),
              AppButton.primary(
                label: 'Sign in',
                expand: true,
                busy: _busy,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(AppColors c, String message) {
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
            child: Text(
              message,
              style: AppTypography.caption.copyWith(color: c.danger),
            ),
          ),
        ],
      ),
    );
  }
}
