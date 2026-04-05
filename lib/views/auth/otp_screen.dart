import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/views/auth/new_password_screen.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  @override
  void dispose() {
    otpController.dispose();
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
                                'Verifikasi OTP',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Masukkan kode yang baru saja kami kirimkan.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColor.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 20),
                              CustomTextField(
                                controller: otpController,
                                hintText: 'Kode OTP',
                                prefixIcon: Icons.password_outlined,
                                keyboardType: TextInputType.number,
                                enableSuggestions: false,
                                validator: (value) {
                                  if ((value ?? '').trim().isEmpty) {
                                    return 'Kode OTP tidak boleh kosong';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'Verifikasi',
                                isLoading: isLoading,
                                onPressed: () async {
                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  setState(() {
                                    isLoading = true;
                                  });

                                  const message = 'OTP berhasil diverifikasi';

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(message)),
                                  );

                                  setState(() {
                                    isLoading = false;
                                  });

                                  context.push(const NewPasswordScreen());
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
