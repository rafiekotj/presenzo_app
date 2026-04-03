import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
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
  void initState() {
    super.initState();
    _checkSavedLogin();
  }

  Future<void> _checkSavedLogin() async {
    final isLogin = await PreferenceHandler.getIsLogin();
    final token = await PreferenceHandler.getToken();

    if (!mounted) return;

    if (isLogin == true && (token?.isNotEmpty ?? false)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.pushAndRemoveAll(const BottomNavbar());
      });
      return;
    }

    setState(() {
      isCheckingSession = false;
    });
  }

  void visibilityOnOff() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isCheckingSession) {
      return const Scaffold(
        backgroundColor: AppColor.backgroundLight,
        body: Center(child: CircularProgressIndicator(color: AppColor.primary)),
      );
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColor.backgroundLight,
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
                          const SizedBox(height: 12),
                          Center(
                            child: Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColor.primarySoft,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                color: AppColor.secondary,
                                size: 32,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Center(
                            child: Text(
                              'presenzo',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: AppColor.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  22,
                                  20,
                                  18,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColor.surface,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColor.border.withValues(
                                      alpha: 0.75,
                                    ),
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x1A1D4ED8),
                                      blurRadius: 20,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Masuk ke akun Anda',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Gunakan email terdaftar untuk melanjutkan.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    CustomTextField(
                                      controller: emailController,
                                      hintText: 'Email',
                                      prefixIcon: Icons.email_outlined,
                                      keyboardType: TextInputType.emailAddress,
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
                                      suffixIcon: InkWell(
                                        onTap: visibilityOnOff,
                                        child: Icon(
                                          size: 20,
                                          isVisibility
                                              ? Icons.visibility
                                              : Icons.visibility_off,
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        top: 12,
                                        bottom: 16,
                                      ),
                                      child: Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: () {
                                            context.push(
                                              const ForgotPasswordScreen(),
                                            );
                                          },
                                          child: const Text(
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
                                    CustomButton(
                                      text: 'Masuk',
                                      isLoading: isLoading,
                                      onPressed: () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
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
                                          message =
                                              login?.message ??
                                              'Login berhasil';

                                          if (token.isNotEmpty) {
                                            await PreferenceHandler()
                                                .storingToken(token);
                                            await PreferenceHandler()
                                                .storingIsLogin(true);
                                          }
                                        } catch (e) {
                                          log(e.toString());
                                          message = e
                                              .toString()
                                              .replaceFirst('Exception: ', '')
                                              .replaceFirst(
                                                'HttpException: ',
                                                '',
                                              )
                                              .trim();
                                        }

                                        if (!context.mounted) return;

                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(content: Text(message)),
                                        );

                                        setState(() {
                                          isLoading = false;
                                        });

                                        if (token.isNotEmpty) {
                                          context.pushAndRemoveAll(
                                            const BottomNavbar(),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push(const RegisterScreen());
                                },
                                child: const Text(
                                  'Daftar',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
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
