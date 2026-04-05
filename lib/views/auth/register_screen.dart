import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/services/api/register.dart';
import 'package:presenzo_app/services/api/update_profile.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_dropdown_field.dart';
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
  bool isLoadingOptions = true;

  List<ProfileOptionItem> trainings = const [];
  List<ProfileOptionItem> batches = const [];
  List<DropdownMenuItem<int>> trainingMenuItems = const [];
  List<DropdownMenuItem<int>> batchMenuItems = const [];
  int? selectedTrainingId;
  int? selectedBatchId;
  String? selectedGender;

  void visibilityOnOff() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDropdownOptions();
  }

  Future<void> _loadDropdownOptions() async {
    setState(() {
      isLoadingOptions = true;
    });

    try {
      final results = await Future.wait([getTrainings(), getBatches()]);
      final loadedTrainings = results[0];
      final loadedBatches = results[1];
      if (!mounted) return;

      setState(() {
        trainings = loadedTrainings;
        batches = loadedBatches;
        trainingMenuItems = trainings
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(item.label),
                ),
              ),
            )
            .toList();
        batchMenuItems = batches
            .map(
              (item) => DropdownMenuItem<int>(
                value: item.id,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(item.label),
                ),
              ),
            )
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal memuat pilihan training/batch. Silakan coba lagi.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoadingOptions = false;
        });
      }
    }
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
                                'Register',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
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
                                    return 'Password minimal 8 karakter';
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
                              CustomDropdownField<String>(
                                selectedValue: selectedGender,
                                hintText: 'Pilih Jenis Kelamin',
                                prefixIcon: Icons.wc_outlined,
                                menuMaxHeight: 220,
                                items: const [
                                  DropdownMenuItem<String>(
                                    value: 'L',
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text('Laki-laki'),
                                    ),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'P',
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                      child: Text('Perempuan'),
                                    ),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    selectedGender = value;
                                  });
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Jenis kelamin wajib dipilih';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              CustomDropdownField<int>(
                                selectedValue: selectedBatchId,
                                hintText: 'Pilih Batch',
                                prefixIcon: Icons.groups_outlined,
                                menuMaxHeight: 280,
                                isLoading: isLoadingOptions,
                                loadingText: 'Memuat batch...',
                                items: isLoadingOptions
                                    ? const [
                                        DropdownMenuItem<int>(
                                          value: -1,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text('Memuat batch...'),
                                          ),
                                        ),
                                      ]
                                    : batchMenuItems,
                                onChanged: isLoadingOptions
                                    ? null
                                    : (value) {
                                        setState(() {
                                          selectedBatchId = value;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Batch wajib dipilih';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              CustomDropdownField<int>(
                                selectedValue: selectedTrainingId,
                                hintText: 'Pilih Jurusan',
                                prefixIcon: Icons.school_outlined,
                                menuMaxHeight: 280,
                                isLoading: isLoadingOptions,
                                loadingText: 'Memuat jurusan...',
                                items: isLoadingOptions
                                    ? const [
                                        DropdownMenuItem<int>(
                                          value: -1,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text('Memuat jurusan...'),
                                          ),
                                        ),
                                      ]
                                    : trainingMenuItems,
                                onChanged: isLoadingOptions
                                    ? null
                                    : (value) {
                                        setState(() {
                                          selectedTrainingId = value;
                                        });
                                      },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Jurusan wajib dipilih';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'Daftar',
                                isLoading: isLoading,
                                onPressed: () async {
                                  if (isLoadingOptions) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Tunggu sampai pilihan selesai dimuat.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }

                                  if (!_formKey.currentState!.validate()) {
                                    return;
                                  }

                                  if (selectedTrainingId == null ||
                                      selectedBatchId == null ||
                                      selectedGender == null ||
                                      selectedGender!.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Jurusan, batch, dan jenis kelamin wajib dipilih.',
                                        ),
                                      ),
                                    );
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
                                      trainingId: selectedTrainingId!,
                                      batchId: selectedBatchId!,
                                      jenisKelamin: selectedGender!,
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

                                  if (!context.mounted) return;

                                  ScaffoldMessenger.of(context).showSnackBar(
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
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                  color: AppColor.textSecondary,
                                  fontSize: 12,
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
