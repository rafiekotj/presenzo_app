import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/services/api/register.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isVisibility = true;
  bool isLoading = false;

  void visibilityOnOff() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                                size: 30,
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
                                      blurRadius: 18,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Text(
                                      'Buat akun baru',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: AppColor.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    const Text(
                                      'Mulai kelola aktivitasmu bersama presenzo.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColor.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    CustomTextField(
                                      controller: nameController,
                                      hintText: 'Nama Lengkap',
                                      prefixIcon: Icons.person,
                                      validator: (value) {
                                        if ((value ?? '').trim().isEmpty) {
                                          return 'Nama tidak boleh kosong';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 10),
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
                                      validator: (value) {
                                        final password = value ?? '';
                                        if (password.isEmpty) {
                                          return 'Password tidak boleh kosong';
                                        }
                                        if (password.length < 6) {
                                          return 'Password minimal 6 karakter';
                                        }
                                        if (!RegExp(
                                          r'[A-Z]',
                                        ).hasMatch(password)) {
                                          return 'Minimal 1 huruf besar';
                                        }
                                        if (!RegExp(
                                          r'[a-z]',
                                        ).hasMatch(password)) {
                                          return 'Minimal 1 huruf kecil';
                                        }
                                        if (!RegExp(r'\d').hasMatch(password)) {
                                          return 'Minimal 1 angka';
                                        }
                                        if (!RegExp(
                                          r'[!@#$%^&*(),.?":{}|<>_\-\\/\[\];\`~+=]',
                                        ).hasMatch(password)) {
                                          return 'Minimal 1 karakter spesial';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 18),
                                    CustomButton(
                                      text: 'Daftar',
                                      isLoading: isLoading,
                                      onPressed: () async {
                                        if (!_formKey.currentState!
                                            .validate()) {
                                          return;
                                        }

                                        setState(() {
                                          isLoading = true;
                                        });

                                        String message = 'Pendaftaran gagal';
                                        bool isSuccess = false;

                                        try {
                                          final result = await registerUser(
                                            name: nameController.text.trim(),
                                            email: emailController.text.trim(),
                                            password: passwordController.text,
                                          );

                                          isSuccess = true;
                                          message =
                                              result?.message ??
                                              'Pendaftaran sukses, silahkan login';
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

                                        if (isSuccess) {
                                          context.pushReplacement(
                                            const LoginScreen(),
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
                                'Sudah punya akun? ',
                                style: TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.pushReplacement(const LoginScreen());
                                },
                                child: const Text(
                                  'Masuk',
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
