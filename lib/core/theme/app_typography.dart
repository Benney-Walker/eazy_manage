import 'package:flutter/material.dart';

/// Typography scale — mirrors the JavaFX text-* classes.
///
/// Font families are DM Sans (UI) and DM Mono (numeric/tabular), bundled as
/// assets. If the .ttf files aren't present yet, Flutter falls back to the
/// platform default gracefully.
///
/// These are colorless on purpose — color is applied by the theme via
/// [TextStyle.color] so the same scale works in light and dark mode. Widgets
/// that need a specific color wrap with `.copyWith(color: ...)`.
abstract final class AppTypography {
  static const String fontSans = 'DMSans';
  static const String fontMono = 'DMMono';

  // Display / headings
  static const TextStyle display = TextStyle(
    fontFamily: fontSans,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontSans,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.2,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: fontSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.45,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle eyebrow = TextStyle(
    fontFamily: fontSans,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: 0.6,
  );

  static const TextStyle label = TextStyle(
    fontFamily: fontSans,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Metric / numeric — DM Mono for tabular alignment
  static const TextStyle metric = TextStyle(
    fontFamily: fontSans,
    fontSize: 30,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -0.5,
  );

  static const TextStyle mono = TextStyle(
    fontFamily: fontMono,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontSans,
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
  );
}
