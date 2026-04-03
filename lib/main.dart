import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null);
  await PreferenceHandler().init();

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Presenzo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: AppColor.primary),
        fontFamily: 'Inter',
        textTheme: const TextTheme().apply(
          bodyColor: AppColor.textPrimary,
          displayColor: AppColor.textPrimary,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}
