import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'theme_mode';

/// Reads the persisted theme synchronously from SharedPreferences.
/// Call this in main() before runApp() so the initial value is always correct.
Future<ThemeMode> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final stored = prefs.getString(_kThemeModeKey);
  return switch (stored) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Initial state is injected via ProviderScope overrides in main().
    // No async loading needed here — value is already correct on first frame.
    return ref.read(initialThemeModeProvider);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }

  Future<void> toggleDarkMode() async {
    await setThemeMode(
      state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark,
    );
  }
}

/// Holds the boot-time theme value injected from main() via ProviderScope overrides.
/// Named with underscore-free name so main.dart can reference it for the override.
final initialThemeModeProvider = Provider<ThemeMode>(
  (_) => ThemeMode.system, // default; overridden in main() before runApp
);

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(
  ThemeNotifier.new,
);
