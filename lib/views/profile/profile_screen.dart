import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  late Future<void> _initialLoadFuture;
  final ImagePicker _imagePicker = ImagePicker();

  Data? _userData;
  List<ProfileOptionItem> _trainings = const [];
  List<ProfileOptionItem> _batches = const [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  int? _selectedTrainingId;
  int? _selectedBatchId;

  Uint8List? _pendingPhotoBytes;
  String? _pendingPhotoBase64;

  bool _isPickingPhoto = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final profileResult = await getUser();

    List<ProfileOptionItem> trainings = const [];
    List<ProfileOptionItem> batches = const [];

    try {
      trainings = await getTrainings();
    } catch (_) {
      trainings = const [];
    }

    try {
      batches = await getBatches();
    } catch (_) {
      batches = const [];
    }

    final user = profileResult?.data;
    _userData = user;
    _trainings = trainings;
    _batches = batches;

    _nameController.text = user?.name ?? '';
    _emailController.text = user?.email ?? '';
    _phoneController.text = user?.phone ?? '';

    _selectedTrainingId = _containsId(trainings, user?.trainingId)
        ? user?.trainingId
        : null;
    _selectedBatchId = _containsId(batches, user?.batchId)
        ? user?.batchId
        : null;
  }

  bool _containsId(List<ProfileOptionItem> items, int? value) {
    if (value == null) return false;
    return items.any((item) => item.id == value);
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

      await updateProfile(
        name: name,
        phone: _phoneController.text.trim(),
        trainingId: _selectedTrainingId,
        batchId: _selectedBatchId,
      );

      final refreshed = await getUser();
      final user = refreshed?.data;

      if (!mounted) return;
      setState(() {
        _userData = user;
        _nameController.text = user?.name ?? _nameController.text;
        _emailController.text = user?.email ?? _emailController.text;
        _phoneController.text = user?.phone ?? _phoneController.text;

        if (_containsId(_trainings, user?.trainingId)) {
          _selectedTrainingId = user?.trainingId;
        }
        if (_containsId(_batches, user?.batchId)) {
          _selectedBatchId = user?.batchId;
        }

        _pendingPhotoBytes = null;
        _pendingPhotoBase64 = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColor.success,
          content: Text('Profil berhasil diperbarui.'),
        ),
      );
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

  Future<void> _reloadDropdownOptions() async {
    try {
      final trainings = await getTrainings();
      final batches = await getBatches();

      if (!mounted) return;
      setState(() {
        _trainings = trainings;
        _batches = batches;

        if (!_containsId(_trainings, _selectedTrainingId)) {
          _selectedTrainingId = null;
        }
        if (!_containsId(_batches, _selectedBatchId)) {
          _selectedBatchId = null;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColor.success,
          content: Text('Pilihan training dan batch berhasil diperbarui.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColor.error,
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    }
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

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColor.primary,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: AppColor.primarySoft,
                              backgroundImage: avatarProvider,
                              child: avatarProvider == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 44,
                                      color: AppColor.primary,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: InkWell(
                              onTap: _isPickingPhoto
                                  ? null
                                  : _showPhotoPickerSheet,
                              borderRadius: BorderRadius.circular(100),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppColor.primarySoft,
                                  ),
                                ),
                                child: _isPickingPhoto
                                    ? const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColor.primary,
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
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColor.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColor.border.withValues(alpha: 0.8),
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 20,
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
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Endpoint aktif: /profile, /profile/photo, /trainings, /batches.',
                            style: TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 20),
                          CustomTextField(
                            controller: _nameController,
                            hintText: 'Nama',
                            prefixIcon: Icons.person,
                          ),
                          const SizedBox(height: 12),
                          CustomTextField(
                            controller: _phoneController,
                            hintText: 'Nomor Telepon',
                            keyboardType: TextInputType.phone,
                            prefixIcon: Icons.phone_outlined,
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
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            value: _selectedTrainingId,
                            isExpanded: true,
                            hint: const Text('Pilih Training'),
                            items: _trainings.isEmpty
                                ? const [
                                    DropdownMenuItem<int>(
                                      value: -1,
                                      child: Text(
                                        'Data training belum tersedia',
                                      ),
                                    ),
                                  ]
                                : _trainings
                                      .map(
                                        (item) => DropdownMenuItem<int>(
                                          value: item.id,
                                          child: Text(item.label),
                                        ),
                                      )
                                      .toList(),
                            onChanged: (value) {
                              if (value == null || value < 0) {
                                return;
                              }
                              setState(() {
                                _selectedTrainingId = value;
                              });
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              prefixIcon: const Icon(
                                Icons.school_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColor.textHint,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int>(
                            value: _selectedBatchId,
                            isExpanded: true,
                            hint: const Text('Pilih Batch'),
                            items: _batches.isEmpty
                                ? const [
                                    DropdownMenuItem<int>(
                                      value: -1,
                                      child: Text('Data batch belum tersedia'),
                                    ),
                                  ]
                                : _batches
                                      .map(
                                        (item) => DropdownMenuItem<int>(
                                          value: item.id,
                                          child: Text(item.label),
                                        ),
                                      )
                                      .toList(),
                            onChanged: (value) {
                              if (value == null || value < 0) {
                                return;
                              }
                              setState(() {
                                _selectedBatchId = value;
                              });
                            },
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.all(12),
                              prefixIcon: const Icon(
                                Icons.groups_outlined,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(
                                  color: AppColor.textHint,
                                ),
                              ),
                            ),
                          ),
                          if (_trainings.isEmpty || _batches.isEmpty) ...[
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: _reloadDropdownOptions,
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text('Muat ulang pilihan'),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          CustomButton(
                            text: 'Simpan Perubahan',
                            isLoading: _isSaving,
                            onPressed: _saveProfile,
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
