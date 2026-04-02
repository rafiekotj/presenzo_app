import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/get_user.dart';
import 'package:presenzo_app/services/api/update_profile.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<GetUserModel?> _profileFuture;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool _isFormInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = getUser();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundLight,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: AppColor.primary),
        ),
        title: const Text(
          'Profil',
          style: TextStyle(
            color: AppColor.textOnPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<GetUserModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColor.secondary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  snapshot.error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColor.error),
                ),
              ),
            );
          }

          final user = snapshot.data?.data;
          if (user == null) {
            return const Center(child: Text('Data profile tidak ditemukan'));
          }

          if (!_isFormInitialized) {
            _nameController.text = user.name ?? '';
            _emailController.text = user.email ?? '';
            _isFormInitialized = true;
          }

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColor.secondary,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A1D4ED8),
                            blurRadius: 24,
                            offset: Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.textOnPrimary,
                                width: 1.5,
                              ),
                            ),
                            child: const CircleAvatar(
                              radius: 32,
                              backgroundColor: AppColor.primarySoft,
                              child: Icon(
                                Icons.person,
                                size: 34,
                                color: AppColor.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _nameController.text,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColor.textOnPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColor.border.withValues(alpha: 0.8),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Edit Profil',
                            style: TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Perbarui profil Anda.',
                            style: TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Nama',
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: 12),
                          AbsorbPointer(
                            child: Stack(
                              children: [
                                CustomTextField(
                                  controller: _emailController,
                                  hintText: 'Email',
                                  prefixIcon: Icons.email_outlined,
                                  readOnly: true,
                                ),
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          CustomButton(
                            text: 'Simpan Perubahan',
                            isLoading: _isSaving,
                            onPressed: () async {
                              setState(() {
                                _isSaving = true;
                              });

                              try {
                                final result = await updateProfile(
                                  name: _nameController.text.trim(),
                                );

                                _nameController.text =
                                    result?.data?.name ?? _nameController.text;

                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColor.success,
                                    content: Text(
                                      result?.message ?? 'Perubahan disimpan',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: AppColor.error,
                                    content: Text(
                                      e.toString().replaceFirst(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                  ),
                                );
                              } finally {
                                if (context.mounted) {
                                  setState(() {
                                    _isSaving = false;
                                  });
                                }
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                          CustomButton(
                            text: 'Logout',
                            isOutlined: true,
                            textColor: AppColor.error,
                            outlineColor: AppColor.error,
                            onPressed: () async {
                              await PreferenceHandler.clearAuthData();
                              if (!context.mounted) return;
                              context.pushAndRemoveAll(const LoginScreen());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
