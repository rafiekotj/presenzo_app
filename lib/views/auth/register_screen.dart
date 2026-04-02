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
                            'Registrasi',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: nameController,
                            hintText: 'Nama',
                            prefixIcon: Icons.person,
                            validator: (value) {
                              if ((value ?? '').trim().isEmpty) {
                                return 'Nama tidak boleh kosong';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),
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
                            validator: (value) {
                              final password = value ?? '';
                              if (password.isEmpty) {
                                return 'Password tidak boleh kosong';
                              }
                              if (password.length < 6) {
                                return 'Password minimal 6 karakter';
                              }
                              if (!RegExp(r'[A-Z]').hasMatch(password)) {
                                return 'Minimal 1 huruf besar';
                              }
                              if (!RegExp(r'[a-z]').hasMatch(password)) {
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
                          const SizedBox(height: 24),
                          CustomButton(
                            text: 'Daftar',
                            isLoading: isLoading,
                            onPressed: () async {
                              if (!_formKey.currentState!.validate()) {
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

                              if (isSuccess) {
                                context.pushReplacement(const LoginScreen());
                              }
                            },
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sudah punya akun? ',
                                style: TextStyle(color: AppColor.textHint),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.pushReplacement(const LoginScreen());
                                },
                                child: const Text(
                                  'Masuk sekarang',
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
