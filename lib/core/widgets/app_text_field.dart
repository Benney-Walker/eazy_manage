import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// A labeled text field — a field label above a text input, matching the
/// `.field-label` + `.input` pairing used throughout the JavaFX forms.
///
/// Wraps [TextField]/[TextFormField]; the actual input styling comes from the
/// theme's [InputDecorationTheme], so this widget only adds the label, hint,
/// and optional helper/error text.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final TextEditingController? controller;
  final bool obscureText;
  final bool enabled;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final int? maxLines;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.controller,
    this.obscureText = false,
    this.enabled = true,
    this.suffixIcon,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(color: c.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          style: AppTypography.body.copyWith(color: c.textPrimary),
          cursorColor: c.brand,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
            suffixIcon: suffixIcon,
            isDense: true,
          ),
        ),
        if (helper != null && errorText == null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            helper!,
            style: AppTypography.caption.copyWith(color: c.textMuted),
          ),
        ],
      ],
    );
  }
}
