import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import 'auth_scaffold.dart';

class SubscriptionScreen extends ConsumerStatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  ConsumerState<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends ConsumerState<SubscriptionScreen> {
  final _schoolName = TextEditingController();
  final _code = TextEditingController();
  bool _busy = false;
  String? _error;

  /// Set once activation succeeds — this is the institution id to enroll under.
  String? _institutionId;

  @override
  void dispose() {
    _schoolName.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _schoolName.text.trim();
    final code = _code.text.trim();
    if (name.isEmpty || code.isEmpty) {
      setState(() => _error = 'Enter your school name and subscription code.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final institutionId = await ref
          .read(authRepositoryProvider)
          .subscribe(institutionName: name, subscriptionCode: code);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _institutionId = institutionId;
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
        _error = 'Couldn\'t activate. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final done = _institutionId != null;

    return AuthScaffold(
      title: done ? 'Institution activated' : 'Register institution',
      subtitle: done
          ? 'Save your institution ID, then enroll the principal account.'
          : 'Activate EazyManage for your school with your subscription code.',
      children: done ? _successBody(c) : _formBody(c),
    );
  }

  List<Widget> _formBody(AppColors c) {
    return [
      AppTextField(
        label: 'School name',
        hint: 'e.g. Daffodils International School',
        controller: _schoolName,
      ),
      const SizedBox(height: AppSpacing.lg),
      AppTextField(
        label: 'Subscription code',
        hint: 'The code from your subscription',
        controller: _code,
        onSubmitted: (_) => _submit(),
      ),
      if (_error != null) ...[
        const SizedBox(height: AppSpacing.lg),
        AuthError(message: _error!),
      ],
      const SizedBox(height: AppSpacing.xl),
      AppButton.primary(
        label: 'Activate institution',
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
    ];
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
            Text('Institution ID',
                style: AppTypography.label.copyWith(color: c.textSecondary)),
            const SizedBox(height: AppSpacing.xs),
            SelectableText(
              _institutionId!,
              style: AppTypography.subtitle.copyWith(color: c.textPrimary),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      AppButton.primary(
        label: 'Enroll principal',
        icon: Icons.arrow_forward_rounded,
        expand: true,
        onPressed: () =>
            context.go('/auth/enroll?institutionId=${_institutionId!}'),
      ),
      const SizedBox(height: AppSpacing.lg),
      Center(
        child: TextButton(
          onPressed: () => context.go('/auth'),
          child: Text('← Back to login',
              style: AppTypography.button.copyWith(color: c.textSecondary)),
        ),
      ),
    ];
  }
}

