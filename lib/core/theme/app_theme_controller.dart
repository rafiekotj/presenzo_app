import 'package:flutter/material.dart';
import 'package:presenzo_app/services/storage/preference.dart';

class AppThemeController {
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  static bool get isDarkMode => themeMode.value == ThemeMode.dark;

  static Future<void> loadInitialTheme() async {
    final savedValue = await PreferenceHandler.getIsDarkMode() ?? false;
    themeMode.value = savedValue ? ThemeMode.dark : ThemeMode.light;
  }

  static Future<void> setDarkMode(bool isDarkMode) async {
    themeMode.value = isDarkMode ? ThemeMode.dark : ThemeMode.light;
    await PreferenceHandler().storingIsDarkMode(isDarkMode);
  }
}
