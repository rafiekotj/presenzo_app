import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/services/api/reset_password.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class NewPasswordScreen extends StatefulWidget {
  const NewPasswordScreen({super.key, required this.email, required this.otp});

  final String email;
  final String otp;

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool isPasswordVisible = true;
  bool isConfirmPasswordVisible = true;
  bool isLoading = false;

  void togglePasswordVisibility() {
    setState(() {
      isPasswordVisible = !isPasswordVisible;
    });
  }

  void toggleConfirmPasswordVisibility() {
    setState(() {
      isConfirmPasswordVisible = !isConfirmPasswordVisible;
    });
  }

  @override
  void dispose() {
    passwordController.dispose();
    confirmPasswordController.dispose();
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
                          const Spacer(),
                          const Center(
                            child: Text(
                              'presenzo',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                color: AppColor.textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Atur ulang kata sandi',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Gunakan kombinasi password yang kuat dan aman.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: passwordController,
                                hintText: 'Password Baru',
                                prefixIcon: Icons.lock_outline,
                                obscureText: isPasswordVisible,
                                enableSuggestions: false,
                                autocorrect: false,
                                suffixIcon: InkWell(
                                  onTap: togglePasswordVisibility,
                                  child: Icon(
                                    size: 20,
                                    isPasswordVisible
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
                              const SizedBox(height: 10),
                              CustomTextField(
                                controller: confirmPasswordController,
                                hintText: 'Konfirmasi Password Baru',
                                prefixIcon: Icons.lock_outline,
                                obscureText: isConfirmPasswordVisible,
                                enableSuggestions: false,
                                autocorrect: false,
                                suffixIcon: InkWell(
                                  onTap: toggleConfirmPasswordVisibility,
                                  child: Icon(
                                    size: 20,
                                    isConfirmPasswordVisible
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                ),
                                validator: (value) {
                                  if ((value ?? '').isEmpty) {
                                    return 'Konfirmasi password tidak boleh kosong';
                                  }
                                  if (value != passwordController.text) {
                                    return 'Password tidak sesuai';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'Simpan Password',
                                isLoading: isLoading,
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  try {
                                    final message = await resetPasswordWithOtp(
                                      email: widget.email,
                                      otp: widget.otp,
                                      password: passwordController.text,
                                    );

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(message)),
                                    );

                                    context.pushAndRemoveAll(
                                      const LoginScreen(),
                                    );
                                  } catch (error) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(error.toString()),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }
                                },
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
