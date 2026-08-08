import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_dimens.dart';
import '../theme/app_typography.dart';

/// The four button intents from the JavaFX design system, as Flutter widgets.
///
/// Usage:
///   AppButton.primary(label: 'Save changes', onPressed: ...)
///   AppButton.secondary(label: 'Cancel', onPressed: ...)
///   AppButton.ghost(label: 'Reset', onPressed: ...)
///   AppButton.danger(label: 'Delete', onPressed: ...)
///
/// Each supports an optional leading icon and a busy state that swaps the
/// content for a small spinner and blocks taps.
enum _Variant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final bool expand;
  final _Variant _variant;

  const AppButton._({
    required this.label,
    required this.onPressed,
    required _Variant variant,
    this.icon,
    this.busy = false,
    this.expand = false,
  }) : _variant = variant;

  const AppButton.primary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool busy = false,
    bool expand = false,
  }) : this._(
          label: label,
          onPressed: onPressed,
          variant: _Variant.primary,
          icon: icon,
          busy: busy,
          expand: expand,
        );

  const AppButton.secondary({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool busy = false,
    bool expand = false,
  }) : this._(
          label: label,
          onPressed: onPressed,
          variant: _Variant.secondary,
          icon: icon,
          busy: busy,
          expand: expand,
        );

  const AppButton.ghost({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool busy = false,
    bool expand = false,
  }) : this._(
          label: label,
          onPressed: onPressed,
          variant: _Variant.ghost,
          icon: icon,
          busy: busy,
          expand: expand,
        );

  const AppButton.danger({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
    bool busy = false,
    bool expand = false,
  }) : this._(
          label: label,
          onPressed: onPressed,
          variant: _Variant.danger,
          icon: icon,
          busy: busy,
          expand: expand,
        );

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final effectiveOnPressed = busy ? null : onPressed;

    final (Color bg, Color fg, BorderSide side) = switch (_variant) {
      _Variant.primary => (c.brand, c.onBrand, BorderSide.none),
      _Variant.secondary => (
          c.surface,
          c.textPrimary,
          BorderSide(color: c.borderStrong, width: AppStroke.hairline),
        ),
      _Variant.ghost => (Colors.transparent, c.textPrimary, BorderSide.none),
      _Variant.danger => (c.danger, c.onDanger, BorderSide.none),
    };

    final child = _content(context, fg);

    final button = _variant == _Variant.ghost
        ? TextButton(
            onPressed: effectiveOnPressed,
            style: TextButton.styleFrom(
              foregroundColor: fg,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
            ),
            child: child,
          )
        : _variant == _Variant.secondary
            ? OutlinedButton(
                onPressed: effectiveOnPressed,
                style: OutlinedButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  side: side,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  shape:
                      const RoundedRectangleBorder(borderRadius: AppRadius.control),
                ),
                child: child,
              )
            : FilledButton(
                onPressed: effectiveOnPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: bg,
                  foregroundColor: fg,
                  disabledBackgroundColor: bg.withValues(alpha: 0.4),
                  disabledForegroundColor: fg.withValues(alpha: 0.7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  elevation: 0,
                  shape:
                      const RoundedRectangleBorder(borderRadius: AppRadius.control),
                ),
                child: child,
              );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }

  Widget _content(BuildContext context, Color fg) {
    if (busy) {
      return SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: fg),
      );
    }
    if (icon == null) {
      return Text(label, style: AppTypography.button);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: AppTypography.button),
      ],
    );
  }
}
