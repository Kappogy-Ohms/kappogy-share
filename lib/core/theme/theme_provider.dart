import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:kappogy_share/features/settings/application/settings_service.dart';

part 'theme_provider.g.dart';

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    final profileAsync = ref.watch(settingsServiceProvider);
    return profileAsync.valueOrNull?.themeMode ?? ThemeMode.system;
  }

  void toggleTheme() {
    ThemeMode next;
    if (state == ThemeMode.light) {
      next = ThemeMode.dark;
    } else if (state == ThemeMode.dark) {
      next = ThemeMode.light;
    } else {
      // If system, manually switch based on current brightness. For now, force dark.
      next = ThemeMode.dark;
    }
    ref.read(settingsServiceProvider.notifier).updateThemeMode(next);
  }

  void setThemeMode(ThemeMode mode) {
    ref.read(settingsServiceProvider.notifier).updateThemeMode(mode);
  }
}
