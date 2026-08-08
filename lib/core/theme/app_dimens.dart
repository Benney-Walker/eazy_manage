import 'package:flutter/widgets.dart';

/// Spacing, radius, and elevation rhythm — mirrors the JavaFX design system:
///   spacing: 2 4 8 12 16 24 32 48 64
///   radius:  4 8 12 16 20
///
/// Use these constants everywhere instead of magic numbers so the whole app
/// shares one rhythm.
abstract final class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double huge = 64;
}

abstract final class AppRadius {
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 16;
  static const double xxl = 20;

  static const Radius smR = Radius.circular(sm);
  static const Radius mdR = Radius.circular(md);
  static const Radius lgR = Radius.circular(lg);
  static const Radius xlR = Radius.circular(xl);

  static const BorderRadius card = BorderRadius.all(lgR);
  static const BorderRadius control = BorderRadius.all(mdR);
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
}

/// Standard hairline border width used across the design system.
abstract final class AppStroke {
  static const double hairline = 1;
  static const double thick = 2;
}
