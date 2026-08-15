import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_providers.dart';

/// Holds the active [ThemeMode] and persists it so the choice survives app
/// restarts. Starts from a default and asynchronously restores the stored
/// preference just after build (the storage read can't block the synchronous
/// build), then writes through on every change.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _restore();
    return ThemeMode.light;
  }

  Future<void> _restore() async {
    final stored = await ref.read(tokenStorageProvider).themeMode;
    final mode = _decode(stored);
    if (mode != null) state = mode;
  }

  void set(ThemeMode mode) {
    state = mode;
    // Fire-and-forget persist; the UI needn't wait on the write.
    ref.read(tokenStorageProvider).setThemeMode(_encode(mode));
  }

  void toggle() {
    final next = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.system => ThemeMode.light,
    };
    set(next);
  }

  bool get isDark => state == ThemeMode.dark;

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode? _decode(String? raw) => switch (raw) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    'system' => ThemeMode.system,
    _ => null,
  };
}

final themeModeProvider =
NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);