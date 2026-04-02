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
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Spacer(),
                          Center(
                            child: Text(
                              "presenzo",
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 64),
                          const Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
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
                          const SizedBox(height: 8),
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: GestureDetector(
                                onTap: () {
                                  context.push(const ForgotPasswordScreen());
                                },
                                child: const Text(
                                  'Lupa Kata Sandi?',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          CustomButton(
                            text: 'Masuk',
                            isLoading: isLoading,
                            onPressed: () async {
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

                                if (token.isNotEmpty) {
                                  await PreferenceHandler().storingToken(token);
                                  await PreferenceHandler().storingIsLogin(
                                    true,
                                  );
                                }
                              } catch (e) {
                                log(e.toString());
                                message = e
                                    .toString()
                                    .replaceFirst('Exception: ', '')
                                    .replaceFirst('HttpException: ', '')
                                    .trim();
                              }

                              if (!mounted) return;

                              ScaffoldMessenger.of(
                                context,
                              ).showSnackBar(SnackBar(content: Text(message)));

                              setState(() {
                                isLoading = false;
                              });

                              if (token.isNotEmpty) {
                                context.pushAndRemoveAll(const BottomNavbar());
                              }
                            },
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(color: AppColor.textHint),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.push(const RegisterScreen());
                                },
                                child: const Text(
                                  'Daftar sekarang',
                                  style: TextStyle(
                                    color: AppColor.primary,
                                    fontWeight: FontWeight.bold,
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
