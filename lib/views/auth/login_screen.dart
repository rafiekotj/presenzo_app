import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/models/login_model.dart';
import 'package:presenzo_app/services/api/login.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/auth/forgot_password_screen.dart';
import 'package:presenzo_app/views/auth/register_screen.dart';
import 'package:presenzo_app/widgets/bottom_navigation/bottom_navbar.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isVisibility = true;
  bool isLoading = false;
  bool isCheckingSession = true;

  @override
  /// Menjalankan inisialisasi awal halaman login dan memeriksa sesi tersimpan.
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  /// Memeriksa status login tersimpan untuk menentukan perlu login ulang atau langsung masuk.
  Future<void> _checkSavedLogin() async {
    final isLogin = await PreferenceHandler.getIsLogin();
    final token = await PreferenceHandler.getToken();

    if (!mounted) return;

    if (isLogin == true && (token?.isNotEmpty ?? false)) {
      _goToHomeAfterFrame();
      return;
    }

    setState(() {
      isCheckingSession = false;
    });
  }

  /// Menavigasi ke halaman utama setelah frame selesai agar perpindahan halaman aman.
  void _goToHomeAfterFrame() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.pushAndRemoveAll(const BottomNavbar());
    });
  }

  /// Mengubah mode tampil atau sembunyi pada input kata sandi.
  void _togglePasswordVisibility() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  /// Menyimpan token dan data sesi pengguna setelah autentikasi berhasil.
  Future<void> _persistLoginSession(LoginModel? login, String token) async {
    if (token.isEmpty) return;

    await PreferenceHandler().storingToken(token);
    await PreferenceHandler().storingIsLogin(true);

    final createdAt = login?.data?.user?.createdAt;
    if (createdAt != null) {
      await PreferenceHandler().storingUserCreatedAt(createdAt);
    }
  }

  /// Menangani alur login dari validasi form, request API, hingga navigasi.
  Future<void> _handleLoginSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    String message = 'Login gagal';
    String token = '';

    try {
      final login = await loginUser(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      token = login?.data?.token ?? '';
      message = login?.message ?? 'Login berhasil';

      await _persistLoginSession(login, token);
    } catch (e) {
      log(e.toString());
      message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('HttpException: ', '')
          .trim();
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));

    setState(() {
      isLoading = false;
    });

    if (token.isNotEmpty) {
      context.pushAndRemoveAll(const BottomNavbar());
    }
  }

  @override
  /// Membersihkan seluruh controller input ketika halaman login ditutup.
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  /// Menyusun tampilan halaman login beserta form, aksi masuk, dan navigasi terkait.
  Widget build(BuildContext context) {
    if (isCheckingSession) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColor.primary,
            strokeWidth: 3.5,
          ),
        ),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Spacer(),
                          Center(
                            child: Image.asset(
                              'assets/icons/presenzo_name.png',
                              height: 84,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              CustomTextField(
                                controller: emailController,
                                hintText: 'Email',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                enableSuggestions: false,
                                autocorrect: false,
                                validator: (value) {
                                  final email = (value ?? '').trim();
                                  if (email.isEmpty) {
                                    return 'Email tidak boleh kosong';
                                  }
                                  if (!email.contains('@')) {
                                    return 'Email tidak valid';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              CustomTextField(
                                controller: passwordController,
                                hintText: 'Kata Sandi',
                                prefixIcon: Icons.lock_outline,
                                obscureText: isVisibility,
                                enableSuggestions: false,
                                autocorrect: false,
                                suffixIcon: InkWell(
                                  onTap: _togglePasswordVisibility,
                                  child: Icon(
                                    size: 20,
                                    isVisibility
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Kata sandi tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              CustomButton(
                                text: 'Masuk',
                                isLoading: isLoading,
                                onPressed: _handleLoginSubmit,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Align(
                                  alignment: Alignment.center,
                                  child: GestureDetector(
                                    onTap: () {
                                      context.push(
                                        const ForgotPasswordScreen(),
                                      );
                                    },
                                    child: Text(
                                      'Lupa kata sandi?',
                                      style: TextStyle(
                                        color: AppColor.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push(const RegisterScreen());
                                },
                                child: Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
