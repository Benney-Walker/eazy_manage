import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimens.dart';
import '../../../core/theme/app_typography.dart';

class AuthScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
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
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [c.brand700, c.brand800],
                            ),
                            borderRadius: const BorderRadius.all(AppRadius.lgR),
                          ),
                          alignment: Alignment.center,
                          child: const Text('E',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Text('EazyManage',
                            style: AppTypography.subtitle
                                .copyWith(color: c.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(title,
                        style: AppTypography.title.copyWith(color: c.textPrimary)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle,
                        style: AppTypography.body.copyWith(color: c.textSecondary)),
                    const SizedBox(height: AppSpacing.xl),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Inline error banner shared by the auth-flow screens.
class AuthError extends StatelessWidget {
  final String message;
  const AuthError({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
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
            child: Text(message,
                style: AppTypography.caption.copyWith(color: c.danger)),
          ),
        ],
      ),
    );
  }
}
