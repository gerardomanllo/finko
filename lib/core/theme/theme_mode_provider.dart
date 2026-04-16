import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/finko_enums.dart';

/// Drives [MaterialApp.themeMode] so theme changes apply immediately (e.g. onboarding).
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// Accepts [ThemePreference] wire names: `light`, `dark`, `system`.
  void setFromPreference(String? raw) {
    final pref = ThemePreference.tryParse(raw);
    state = switch (pref) {
      ThemePreference.light => ThemeMode.light,
      ThemePreference.dark => ThemeMode.dark,
      ThemePreference.system => ThemeMode.system,
      null => ThemeMode.system,
    };
  }
}
