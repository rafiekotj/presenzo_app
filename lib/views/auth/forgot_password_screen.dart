import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/views/auth/otp_screen.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
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
                                'Lupa kata sandi?',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Masukkan email akunmu untuk menerima kode OTP.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColor.textSecondary,
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
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'Kirim Kode OTP',
                                isLoading: isLoading,
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  final message =
                                      'Kode OTP telah dikirim ke email Anda';

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );

                                  setState(() {
                                    isLoading = false;
                                  });

                                  context.push(const OtpScreen());
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
