import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────
// Keys
// ─────────────────────────────────────────────

const _kThemeKey = 'nexchat_theme_mode';

// ─────────────────────────────────────────────
// ThemeMode Notifier
// ─────────────────────────────────────────────

class ThemeModeNotifier extends AsyncNotifier<ThemeMode> {
  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeKey);
    return _fromString(stored);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = AsyncData(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeKey, _toString(mode));
  }

  Future<void> toggle() async {
    final current = state.valueOrNull ?? ThemeMode.light;
    final next =
    current == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setTheme(next);
  }

  static ThemeMode _fromString(String? value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.light;
    }
  }

  static String _toString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
      default:
        return 'light';
    }
  }
}

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

/// The main theme provider — watch this in MaterialApp.
final themeModeProvider =
AsyncNotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// Convenience: resolves ThemeMode, defaulting to light during loading.
final resolvedThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeModeProvider).valueOrNull ?? ThemeMode.light;
});

/// Convenience: true when dark mode is active.
final isDarkProvider = Provider<bool>((ref) {
  return ref.watch(resolvedThemeModeProvider) == ThemeMode.dark;
});