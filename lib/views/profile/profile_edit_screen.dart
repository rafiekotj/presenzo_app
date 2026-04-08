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

  // Membersihkan semua controller saat widget ditutup.
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _jenisKelaminController.dispose();
    _batchController.dispose();
    _trainingController.dispose();
    super.dispose();
  }

  // Menjalankan proses awal untuk memuat data profil.
  @override
  void initState() {
    super.initState();
    _initialLoadFuture = _loadInitialData();
  }

  // Mengubah kode gender dari API menjadi teks yang mudah dibaca.
  String _genderLabel(String? code) {
    if (code == 'L') return 'Laki-laki';
    if (code == 'P') return 'Perempuan';
    return '-';
  }

  // Mengisi field form berdasarkan data user yang diterima.
  void _fillFormFromUser(Data? user, {bool keepTypedName = false}) {
    _nameController.text = keepTypedName
        ? _nameController.text
        : (user?.name ?? '');
    _emailController.text = user?.email ?? '';
    _jenisKelaminController.text = _genderLabel(user?.jenisKelamin);
    _batchController.text = user?.batch?.batchKe ?? '-';
    _trainingController.text = user?.training?.title ?? '-';
  }

  // Menampilkan pesan ke pengguna menggunakan SnackBar.
  void _showAppSnackBar(String message, {required Color backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: backgroundColor, content: Text(message)),
    );
  }

  // Merapikan teks error agar lebih singkat untuk ditampilkan.
  String _readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  // Mencoba decode string base64 ke bytes gambar.
  Uint8List? _tryDecodeBase64Image(String value) {
    try {
      return base64Decode(value);
    } catch (_) {
      return null;
    }
  }

  // Membuat tampilan field read-only dengan overlay nonaktif.
  Widget _buildReadOnlyField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required Color disabledFieldOverlay,
  }) {
    return AbsorbPointer(
      child: Stack(
        children: [
          CustomTextField(
            controller: controller,
            hintText: hintText,
            prefixIcon: prefixIcon,
            readOnly: true,
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: disabledFieldOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mengambil data user terbaru dari API.
  Future<Data?> _fetchUserData() async {
    final profileResult = await getUser();
    return profileResult?.data;
  }

  // Memuat data awal lalu mengisi form.
  Future<void> _loadInitialData() async {
    final user = await _fetchUserData();
    _userData = user;

    _fillFormFromUser(user);
  }

  // Menampilkan bottom sheet untuk memilih sumber foto.
  Future<void> _showPhotoPickerSheet() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                Text(
                  'Ganti Foto Profil',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(
                    Icons.photo_camera_outlined,
                    color: AppColor.primary,
                  ),
                  title: Text('Ambil dari Kamera'),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 4),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  leading: Icon(
                    Icons.photo_library_outlined,
                    color: AppColor.primary,
                  ),
                  title: Text('Pilih dari Galeri'),
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

  // Memilih gambar profil dari kamera atau galeri.
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
      _showAppSnackBar(_readableError(error), backgroundColor: AppColor.error);
    } finally {
      if (mounted) {
        setState(() {
          _isPickingPhoto = false;
        });
      }
    }
  }

  // Menentukan sumber gambar avatar yang akan ditampilkan.
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
        final rawBase64 = rawPhoto.substring(commaIndex + 1);
        final bytes = _tryDecodeBase64Image(rawBase64);
        if (bytes != null) return MemoryImage(bytes);
      }
    }

    final bytes = _tryDecodeBase64Image(rawPhoto);
    if (bytes != null) return MemoryImage(bytes);

    return null;
  }

  // Menyimpan perubahan profil dan memuat ulang data user.
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showAppSnackBar(
        'Nama tidak boleh kosong.',
        backgroundColor: AppColor.error,
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

      final user = await _fetchUserData();

      if (!mounted) return;
      setState(() {
        _userData = user;
        _fillFormFromUser(user, keepTypedName: true);

        _pendingPhotoBytes = null;
        _pendingPhotoBase64 = null;
      });

      _showAppSnackBar(
        'Profil berhasil diperbarui.',
        backgroundColor: AppColor.success,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (error) {
      _showAppSnackBar(_readableError(error), backgroundColor: AppColor.error);
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
    final theme = Theme.of(context);
    final primaryText = theme.colorScheme.onSurface;
    final isDarkMode = theme.brightness == Brightness.dark;
    final disabledFieldOverlay = isDarkMode
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.black.withValues(alpha: 0.1);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: primaryText,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: true,
        title: Text(
          'Edit Profil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: primaryText,
          ),
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
                      style: TextStyle(color: AppColor.error),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _initialLoadFuture = _loadInitialData();
                        });
                      },
                      child: Text('Coba Lagi'),
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
                                                  ? Icon(
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
                                                color:
                                                    theme.colorScheme.surface,
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
                                                  : Icon(
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
                                  _buildReadOnlyField(
                                    controller: _emailController,
                                    hintText: 'Email',
                                    prefixIcon: Icons.email_outlined,
                                    disabledFieldOverlay: disabledFieldOverlay,
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
                                  _buildReadOnlyField(
                                    controller: _jenisKelaminController,
                                    hintText: 'Jenis Kelamin',
                                    prefixIcon: Icons.wc_outlined,
                                    disabledFieldOverlay: disabledFieldOverlay,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildReadOnlyField(
                                    controller: _batchController,
                                    hintText: 'Batch',
                                    prefixIcon: Icons.groups_outlined,
                                    disabledFieldOverlay: disabledFieldOverlay,
                                  ),
                                  const SizedBox(height: 10),
                                  _buildReadOnlyField(
                                    controller: _trainingController,
                                    hintText: 'Training',
                                    prefixIcon: Icons.school_outlined,
                                    disabledFieldOverlay: disabledFieldOverlay,
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
