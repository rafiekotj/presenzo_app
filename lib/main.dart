import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/theme/app_theme_controller.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await PreferenceHandler().init();
  await AppThemeController.loadInitialTheme();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: AppColor.primary,
      statusBarBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(seedColor: AppColor.primary),
      scaffoldBackgroundColor: AppColor.backgroundLight,
      cardColor: AppColor.surface,
      fontFamily: 'Inter',
      textTheme: const TextTheme().apply(
        bodyColor: AppColor.textPrimary,
        displayColor: AppColor.textPrimary,
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkSurface = Color(0xFF13302A);
    const darkTextSecondary = Color(0xFFD8E8E3);
    const darkPrimaryText = Color(0xFFF3FAF7);

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: AppColor.primary,
      brightness: Brightness.dark,
    );
    final darkColorScheme = baseColorScheme.copyWith(
      surface: darkSurface,
      onSurface: darkPrimaryText,
      onSurfaceVariant: darkTextSecondary,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
    );

    return ThemeData(
      brightness: Brightness.dark,
      colorScheme: darkColorScheme,
      scaffoldBackgroundColor: AppColor.backgroundDark,
      cardColor: darkSurface,
      fontFamily: 'Inter',
      textTheme: const TextTheme().apply(
        bodyColor: darkPrimaryText,
        displayColor: darkPrimaryText,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColor.backgroundDark,
        foregroundColor: darkPrimaryText,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: AppColor.primarySoft,
        unselectedItemColor: darkTextSecondary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppThemeController.themeMode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Presenzo',
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          themeMode: themeMode,
          home: const LoginScreen(),
        );
      },
    );
  }
}
