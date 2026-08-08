import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_typography.dart';

/// Builds the [ThemeData] for light and dark modes from the token layers.
///
/// Everything flows from [AppColors]; this file wires those tokens into the
/// Material widgets so stock components (buttons, inputs, dialogs, etc.) look
/// right without per-widget overrides. Custom widgets read [AppColors.of].
abstract final class AppTheme {
  static ThemeData light() => _build(AppColors.light, Brightness.light);
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData _build(AppColors c, Brightness brightness) {
    final baseTextColor = c.textPrimary;

    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: c.brand,
      onPrimary: c.onBrand,
      primaryContainer: c.brand50,
      onPrimaryContainer: c.brand800,
      secondary: c.info,
      onSecondary: c.textInverse,
      error: c.danger,
      onError: c.onDanger,
      surface: c.surface,
      onSurface: c.textPrimary,
      surfaceContainerHighest: c.surfaceAlt,
      outline: c.border,
      outlineVariant: c.borderStrong,
      shadow: c.shadow,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.surface,
      dividerColor: c.divider,
      fontFamily: AppTypography.fontSans,
      splashFactory: InkSparkle.splashFactory,

      // ---- Register the color extension so AppColors.of(context) works ----
      extensions: <ThemeExtension<dynamic>>[c],

      textTheme: _textTheme(baseTextColor, c.textSecondary),

      // ---- Cards ----------------------------------------------------------
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.card,
          side: BorderSide(color: c.border, width: AppStroke.hairline),
        ),
      ),

      // ---- Dividers -------------------------------------------------------
      dividerTheme: DividerThemeData(
        color: c.divider,
        thickness: AppStroke.hairline,
        space: AppStroke.hairline,
      ),

      // ---- Inputs ---------------------------------------------------------
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.inputBg,
        hintStyle: AppTypography.body.copyWith(color: c.inputPlaceholder),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.inputBorder, width: AppStroke.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.inputBorder, width: AppStroke.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.inputBorderFocus, width: AppStroke.thick),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.danger, width: AppStroke.hairline),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.danger, width: AppStroke.thick),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.control,
          borderSide: BorderSide(color: c.border, width: AppStroke.hairline),
        ),
      ),

      // ---- Filled (primary) buttons --------------------------------------
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: c.brand,
          foregroundColor: c.onBrand,
          disabledBackgroundColor: c.brand.withValues(alpha: 0.4),
          disabledForegroundColor: c.onBrand.withValues(alpha: 0.7),
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
          elevation: 0,
        ),
      ),

      // ---- Outlined (secondary) buttons ----------------------------------
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.textPrimary,
          backgroundColor: c.surface,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          side: BorderSide(color: c.borderStrong, width: AppStroke.hairline),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),

      // ---- Text (ghost) buttons ------------------------------------------
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.textPrimary,
          textStyle: AppTypography.button,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        ),
      ),

      // ---- Checkboxes / radios / switches --------------------------------
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.brand;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(c.onBrand),
        side: BorderSide(color: c.borderStrong, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(AppRadius.smR),
        ),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.brand;
          return c.borderStrong;
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.onBrand;
          return c.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return c.brand;
          return c.borderStrong;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // ---- Chips ----------------------------------------------------------
      chipTheme: ChipThemeData(
        backgroundColor: c.surfaceAlt,
        labelStyle: AppTypography.caption.copyWith(color: c.textSecondary),
        side: BorderSide(color: c.border, width: AppStroke.hairline),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
      ),

      // ---- Dialogs --------------------------------------------------------
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: const BorderRadius.all(AppRadius.xlR),
          side: BorderSide(color: c.border, width: AppStroke.hairline),
        ),
        titleTextStyle: AppTypography.subtitle.copyWith(color: c.textPrimary),
        contentTextStyle: AppTypography.body.copyWith(color: c.textSecondary),
      ),

      // ---- Tooltips -------------------------------------------------------
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: brightness == Brightness.light
              ? const Color(0xFF1A1A17)
              : const Color(0xFFE8EDF2),
          borderRadius: const BorderRadius.all(AppRadius.smR),
        ),
        textStyle: AppTypography.caption.copyWith(
          color: brightness == Brightness.light
              ? const Color(0xFFFCFCFB)
              : const Color(0xFF0A0F16),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),

      // ---- Scrollbars -----------------------------------------------------
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(c.borderStrong),
        thickness: WidgetStateProperty.all(8),
        radius: const Radius.circular(6),
      ),

      // ---- Tabs -----------------------------------------------------------
      tabBarTheme: TabBarThemeData(
        labelColor: c.textPrimary,
        unselectedLabelColor: c.textSecondary,
        labelStyle: AppTypography.button,
        unselectedLabelStyle: AppTypography.button,
        indicatorColor: c.brand,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: c.divider,
      ),

      // ---- Snackbars ------------------------------------------------------
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surfaceElevated,
        contentTextStyle: AppTypography.body.copyWith(color: c.textPrimary),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.control),
        behavior: SnackBarBehavior.floating,
      ),

      // ---- Progress indicators -------------------------------------------
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.brand,
        linearTrackColor: c.surfaceAlt,
        circularTrackColor: c.surfaceAlt,
      ),
    );
  }

  static TextTheme _textTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: primary),
      titleLarge: AppTypography.title.copyWith(color: primary),
      titleMedium: AppTypography.subtitle.copyWith(color: primary),
      bodyMedium: AppTypography.body.copyWith(color: primary),
      bodySmall: AppTypography.caption.copyWith(color: secondary),
      labelLarge: AppTypography.button.copyWith(color: primary),
      labelMedium: AppTypography.label.copyWith(color: secondary),
      labelSmall: AppTypography.eyebrow.copyWith(color: secondary),
    );
  }
}
