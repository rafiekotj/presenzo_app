import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/get_user.dart';
import 'package:presenzo_app/services/api/profile_photo.dart';
import 'package:presenzo_app/services/api/update_profile.dart';
import 'package:presenzo_app/widgets/custom_button.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late Future<void> _initialLoadFuture;
  final ImagePicker _imagePicker = ImagePicker();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  Data? _userData;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _jenisKelaminController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _trainingController = TextEditingController();

  Uint8List? _pendingPhotoBytes;
  String? _pendingPhotoBase64;

  bool _isPickingPhoto = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _jenisKelaminController.dispose();
    _batchController.dispose();
    _trainingController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profileResult = await getUser();
    final user = profileResult?.data;
    _userData = user;

    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _jenisKelaminController.text = user?.jenisKelamin == 'L'
        ? 'Laki-laki'
        : user?.jenisKelamin == 'P'
        ? 'Perempuan'
        : '-';
    _batchController.text = user?.batch?.batchKe ?? '-';
    _trainingController.text = user?.training?.title ?? '-';
  }

  Future<void> _showPhotoPickerSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColor.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColor.divider,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColor.primary,
                  ),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 4),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: const Icon(
                    Icons.photo_library_outlined,
                    color: AppColor.primary,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;
    await _pickProfileImage(source);
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    if (_isPickingPhoto) return;

    setState(() {
      _isPickingPhoto = true;
    });

    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (picked == null) return;

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _pendingPhotoBytes = bytes;
        _pendingPhotoBase64 = base64Encode(bytes);
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColor.error,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  ImageProvider? _buildAvatarProvider() {
    if (_pendingPhotoBytes != null) {
      return MemoryImage(_pendingPhotoBytes!);
    }

    final rawPhoto = (_userData?.photoUrl ?? '').trim();
    if (rawPhoto.isEmpty) return null;

    if (rawPhoto.startsWith('http://') || rawPhoto.startsWith('https://')) {
      return NetworkImage(rawPhoto);
    }

    if (rawPhoto.startsWith('data:image')) {
      final commaIndex = rawPhoto.indexOf(',');
      if (commaIndex > -1 && commaIndex + 1 < rawPhoto.length) {
        try {
          final rawBase64 = rawPhoto.substring(commaIndex + 1);
          final bytes = base64Decode(rawBase64);
          return MemoryImage(bytes);
        } catch (_) {
          return null;
        }
      }
    }

    try {
      final bytes = base64Decode(rawPhoto);
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColor.error,
          content: Text('Nama tidak boleh kosong.'),
        ),
      );
      return;
    }

    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    try {
      if (_pendingPhotoBase64 != null && _pendingPhotoBase64!.isNotEmpty) {
        await updateProfilePhotoBase64(base64Image: _pendingPhotoBase64!);
      }

      await updateProfile(name: name);

      final refreshed = await getUser();
      final user = refreshed?.data;

      if (!mounted) return;
      setState(() {
        _userData = user;
        _nameController.text = user?.name ?? _nameController.text;
        _emailController.text = user?.email ?? _emailController.text;
        _jenisKelaminController.text = user?.jenisKelamin == 'L'
            ? 'Laki-laki'
            : user?.jenisKelamin == 'P'
            ? 'Perempuan'
            : '-';
        _batchController.text = user?.batch?.batchKe ?? '-';
        _trainingController.text = user?.training?.title ?? '-';

        _pendingPhotoBytes = null;
        _pendingPhotoBase64 = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColor.success,
          content: Text('Profil berhasil diperbarui.'),
        ),
      );

      // Pop with true to indicate successful update
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColor.error,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColor.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColor.backgroundLight,
        foregroundColor: AppColor.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        title: const Text(
          'Edit Profil',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
      ),
      body: FutureBuilder<void>(
        future: _initialLoadFuture,
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColor.error),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _initialLoadFuture = _loadInitialData();
                        });
                      },
                      child: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = _userData;
          if (user == null) {
            return const Center(child: Text('Data profile tidak ditemukan'));
          }

          final avatarProvider = _buildAvatarProvider();

          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
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
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: 124,
                                          height: 124,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: AppColor.primary,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  AppColor.primarySoft,
                                              backgroundImage: avatarProvider,
                                              child: avatarProvider == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      size: 56,
                                                      color: AppColor.primary,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 0,
                                          bottom: 0,
                                          child: InkWell(
                                            onTap: _isPickingPhoto
                                                ? null
                                                : _showPhotoPickerSheet,
                                            borderRadius: BorderRadius.circular(
                                              100,
                                            ),
                                            child: Container(
                                              width: 32,
                                              height: 32,
                                              decoration: BoxDecoration(
                                                color: AppColor.surface,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppColor.primarySoft,
                                                ),
                                              ),
                                              child: _isPickingPhoto
                                                  ? const Padding(
                                                      padding: EdgeInsets.all(
                                                        8,
                                                      ),
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColor
                                                                .primary,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.camera_alt_outlined,
                                                      color: AppColor.primary,
                                                      size: 16,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 40),
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
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  CustomTextField(
                                    controller: _nameController,
                                    hintText: 'Nama',
                                    prefixIcon: Icons.person,
                                    validator: (value) {
                                      if ((value ?? '').trim().isEmpty) {
                                        return 'Nama tidak boleh kosong';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 10),
                                  AbsorbPointer(
                                    child: Stack(
                                      children: [
                                        CustomTextField(
                                          controller: _jenisKelaminController,
                                          hintText: 'Jenis Kelamin',
                                          prefixIcon: Icons.wc_outlined,
                                          readOnly: true,
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AbsorbPointer(
                                    child: Stack(
                                      children: [
                                        CustomTextField(
                                          controller: _batchController,
                                          hintText: 'Batch',
                                          prefixIcon: Icons.groups_outlined,
                                          readOnly: true,
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  AbsorbPointer(
                                    child: Stack(
                                      children: [
                                        CustomTextField(
                                          controller: _trainingController,
                                          hintText: 'Training',
                                          prefixIcon: Icons.school_outlined,
                                          readOnly: true,
                                        ),
                                        Positioned.fill(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  CustomButton(
                                    text: 'Simpan Perubahan',
                                    isLoading: _isSaving,
                                    onPressed: _saveProfile,
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
          );
        },
      ),
    );
  }
}
