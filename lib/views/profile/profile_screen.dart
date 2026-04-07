import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/core/extensions/navigator.dart';
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/get_user.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/auth/login_screen.dart';
import 'package:presenzo_app/views/profile/profile_edit_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<GetUserModel?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = getUser();
  }

  void _refreshProfile() {
    setState(() {
      _profileFuture = getUser();
    });
  }

  ImageProvider? _buildAvatarProvider(String? photoUrl) {
    final rawPhoto = (photoUrl ?? '').trim();
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColor.backgroundDark
        : AppColor.backgroundLight;
    final surfaceColor = isDark ? const Color(0xFF1E293B) : AppColor.surface;
    final textPrimary = isDark ? AppColor.surface : AppColor.textPrimary;
    final textSecondary = isDark
        ? const Color(0xFFCBD5E1)
        : AppColor.textSecondary;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Profil',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<GetUserModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final user = snapshot.data?.data;
          final name = (user?.name ?? 'Pengguna').trim();
          final email = (user?.email ?? '-').trim();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x120F172A),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColor.primary, width: 2),
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppColor.primarySoft,
                          backgroundImage: _buildAvatarProvider(user?.photoUrl),
                          child: _buildAvatarProvider(user?.photoUrl) == null
                              ? const Icon(
                                  Icons.person,
                                  color: AppColor.primary,
                                  size: 34,
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              email,
                              style: TextStyle(
                                fontSize: 12,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColor.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Akun',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gunakan tombol di bawah untuk mengubah profil atau keluar dari akun.',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final result = await Navigator.of(context).push(
                        MaterialPageRoute<bool>(
                          builder: (_) => const ProfileEditScreen(),
                        ),
                      );
                      // Refresh profile if edit was successful
                      if (result == true && mounted) {
                        _refreshProfile();
                      }
                    },
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profil'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: AppColor.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await PreferenceHandler.clearAuthData();
                      if (!context.mounted) return;
                      context.pushAndRemoveAll(const LoginScreen());
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Logout'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColor.error,
                      side: const BorderSide(color: AppColor.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
