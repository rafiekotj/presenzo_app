import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/models/batch_model.dart';
import 'package:presenzo_app/models/training_model.dart';
import 'package:presenzo_app/services/api/batch.dart';
import 'package:presenzo_app/services/api/register.dart';
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

  late final GlobalKey<State<CustomDropdownField<int>>> _trainingDropdownKey =
      GlobalKey();
  late final GlobalKey<State<CustomDropdownField<int>>> _batchDropdownKey =
      GlobalKey();
  late final GlobalKey<State<CustomDropdownField<String>>> _genderDropdownKey =
      GlobalKey();

  bool isVisibility = true;
  bool isLoading = false;
  bool isLoadingOptions = true;

  List<BatchOptionItem> batches = const [];
  List<DropdownMenuItem<int>> trainingMenuItems = const [];
  List<DropdownMenuItem<int>> batchMenuItems = const [];
  int? selectedTrainingId;
  int? selectedBatchId;
  String? selectedGender;

  @override
  /// Menjalankan inisialisasi awal halaman register dan memuat opsi dropdown.
  void initState() {
    super.initState();
    _loadDropdownOptions();
  }

  /// Mengubah mode tampil atau sembunyi pada input kata sandi.
  void _togglePasswordVisibility() {
    setState(() {
      isVisibility = !isVisibility;
    });
  }

  /// Menyusun daftar item dropdown integer dari data API agar konsisten dipakai di UI.
  List<DropdownMenuItem<int>> _buildMenuItems<T>(
    List<T> items, {
    required int? Function(T item) idSelector,
    required String Function(T item) labelSelector,
  }) {
    return items
        .map(
          (item) => DropdownMenuItem<int>(
            value: idSelector(item),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(labelSelector(item)),
            ),
          ),
        )
        .toList();
  }

  List<TrainingOptionItem> _getTrainingsByBatch(int? batchId) {
    if (batchId == null) {
      return const [];
    }

    for (final batch in batches) {
      if (batch.id == batchId) {
        return batch.trainings;
      }
    }

    return const [];
  }

  void _handleBatchChanged(int? batchId) {
    final nextTrainings = _getTrainingsByBatch(batchId);
    final isSelectedTrainingStillAvailable = nextTrainings.any(
      (item) => item.id == selectedTrainingId,
    );

    setState(() {
      selectedBatchId = batchId;
      trainingMenuItems = _buildMenuItems<TrainingOptionItem>(
        nextTrainings,
        idSelector: (item) => item.id,
        labelSelector: (item) => item.label,
      );

      if (!isSelectedTrainingStillAvailable) {
        selectedTrainingId = null;
      }
    });
  }

  /// Memuat data batch lalu mengubahnya menjadi item dropdown.
  Future<void> _loadDropdownOptions() async {
    setState(() {
      isLoadingOptions = true;
    });

    try {
      final loadedBatches = await getBatches();
      if (!mounted) return;

      setState(() {
        batches = loadedBatches;
        batchMenuItems = _buildMenuItems<BatchOptionItem>(
          batches,
          idSelector: (item) => item.id,
          labelSelector: (item) => item.label,
        );
        trainingMenuItems = const [];
      });
    } catch (e) {
      _showMessage('Gagal memuat pilihan training/batch. Silakan coba lagi.');
    } finally {
      if (mounted) {
        setState(() {
          isLoadingOptions = false;
        });
      }
    }
  }

  /// Menampilkan pesan singkat ke pengguna dengan tampilan snackbar yang konsisten.
  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Memvalidasi seluruh dropdown wajib agar submit hanya berjalan saat data lengkap.
  bool _validateRequiredDropdowns() {
    final genderError = (_genderDropdownKey.currentState as dynamic)
        ?.validate();
    final batchError = (_batchDropdownKey.currentState as dynamic)?.validate();
    final trainingError = (_trainingDropdownKey.currentState as dynamic)
        ?.validate();

    return genderError == null && batchError == null && trainingError == null;
  }

  /// Menangani alur register dari validasi form hingga navigasi ke halaman login.
  Future<void> _handleRegisterSubmit() async {
    if (isLoadingOptions) {
      _showMessage('Tunggu sampai pilihan selesai dimuat.');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_validateRequiredDropdowns()) {
      return;
    }

    setState(() {
      isLoading = true;
    });

    String message = 'Pendaftaran gagal';
    var isSuccess = false;

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
      message = result?.message ?? 'Pendaftaran sukses, silahkan login';
    } catch (e) {
      log(e.toString());
      message = e
          .toString()
          .replaceFirst('Exception: ', '')
          .replaceFirst('HttpException: ', '')
          .trim();
    }

    if (!context.mounted) return;

    _showMessage(message);

    setState(() {
      isLoading = false;
    });

    if (isSuccess) {
      context.pushReplacement(const LoginScreen());
    }
  }

  @override
  /// Membersihkan seluruh controller input saat halaman register ditutup.
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  /// Menyusun tampilan halaman register beserta field, dropdown, dan aksi daftar.
  Widget build(BuildContext context) {
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
                                'Register',
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
                                  onTap: _togglePasswordVisibility,
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
                                key: _genderDropdownKey,
                                selectedValue: selectedGender,
                                hintText: 'Jenis Kelamin',
                                prefixIcon: Icons.wc_outlined,
                                menuMaxHeight: 220,
                                isRequired: true,
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
                              ),
                              const SizedBox(height: 10),
                              CustomDropdownField<int>(
                                key: _batchDropdownKey,
                                selectedValue: selectedBatchId,
                                hintText: 'Batch',
                                prefixIcon: Icons.groups_outlined,
                                menuMaxHeight: 280,
                                isLoading: isLoadingOptions,
                                loadingText: 'Memuat batch...',
                                isRequired: true,
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
                                    : _handleBatchChanged,
                              ),
                              const SizedBox(height: 10),
                              CustomDropdownField<int>(
                                key: _trainingDropdownKey,
                                selectedValue: selectedTrainingId,
                                hintText: 'Jurusan',
                                prefixIcon: Icons.school_outlined,
                                menuMaxHeight: 280,
                                isLoading: isLoadingOptions,
                                loadingText: 'Memuat jurusan...',
                                isRequired: true,
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
                              ),
                              const SizedBox(height: 20),
                              CustomButton(
                                text: 'Daftar',
                                isLoading: isLoading,
                                onPressed: _handleRegisterSubmit,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Sudah punya akun? ',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  context.pushReplacement(const LoginScreen());
                                },
                                child: Text(
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
