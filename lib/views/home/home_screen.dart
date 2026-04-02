import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/get_user.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<GetUserModel?> _profileFuture;
  Timer? _clockTimer;
  DateTime _currentDateTime = DateTime.now();

  List<_AttendanceHistoryEntry> get _attendanceHistory {
    final workdays = <DateTime>[];
    var cursor = DateTime(
      _currentDateTime.year,
      _currentDateTime.month,
      _currentDateTime.day,
    );

    while (workdays.length < 5) {
      if (cursor.weekday != DateTime.saturday &&
          cursor.weekday != DateTime.sunday) {
        workdays.add(cursor);
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return workdays.asMap().entries.map((entry) {
      final index = entry.key;
      final date = entry.value;

      switch (index) {
        case 0:
          return _AttendanceHistoryEntry(
            date: date,
            status: _AttendanceStatus.present,
            detail: 'Check In - 07:37',
          );
        case 1:
          return _AttendanceHistoryEntry(
            date: date,
            status: _AttendanceStatus.late,
            detail: '08:32 - 15:35',
          );
        case 2:
          return _AttendanceHistoryEntry(
            date: date,
            status: _AttendanceStatus.leave,
            detail: 'Izin - Keperluan pribadi',
          );
        case 3:
          return _AttendanceHistoryEntry(
            date: date,
            status: _AttendanceStatus.absent,
            detail: 'Tidak ada catatan absen',
          );
        default:
          return _AttendanceHistoryEntry(
            date: date,
            status: _AttendanceStatus.present,
            detail: '07:47 - 15:03',
          );
      }
    }).toList();
  }

  Widget _buildAttendanceItem(_AttendanceHistoryEntry entry) {
    final formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'id_ID',
    ).format(entry.date);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColor.border.withValues(alpha: 0.75)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(entry.icon, color: entry.color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.detail,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColor.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: entry.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              entry.statusLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: entry.color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _profileFuture = getUser();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColor.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 72,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Text(
          'Presenzo',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColor.primary,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A1D4ED8),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: SafeArea(
        child: FutureBuilder<GetUserModel?>(
          future: _profileFuture,
          builder: (context, snapshot) {
            final profileName = snapshot.data?.data?.name?.trim();
            final displayName = (profileName == null || profileName.isEmpty)
                ? 'Pengguna'
                : profileName;
            final attendanceHistory = _attendanceHistory;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x1A1D4ED8),
                          blurRadius: 22,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.18),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                              ),
                              child: const Icon(
                                Icons.work_history,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Selamat datang',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Siap untuk absen hari ini? Pastikan status kehadiran Anda selalu terpantau dengan rapi.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 14,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('HH:mm:ss').format(_currentDateTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM y',
                            'id_ID',
                          ).format(_currentDateTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColor.border.withValues(alpha: 0.7),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F0F172A),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColor.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.fingerprint,
                                  color: AppColor.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Check In',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColor.border.withValues(alpha: 0.7),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x0F0F172A),
                                blurRadius: 16,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColor.success.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: AppColor.success,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'Check Out',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColor.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Riwayat Kehadiran',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (
                    var index = 0;
                    index < attendanceHistory.length;
                    index++
                  ) ...[
                    _buildAttendanceItem(attendanceHistory[index]),
                    if (index != attendanceHistory.length - 1)
                      const SizedBox(height: 12),
                  ],
                  if (snapshot.hasError) ...[
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString(),
                      style: const TextStyle(
                        color: AppColor.error,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

enum _AttendanceStatus { present, leave, late, absent }

class _AttendanceHistoryEntry {
  const _AttendanceHistoryEntry({
    required this.date,
    required this.status,
    required this.detail,
  });

  final DateTime date;
  final _AttendanceStatus status;
  final String detail;

  String get statusLabel {
    switch (status) {
      case _AttendanceStatus.present:
        return 'Hadir';
      case _AttendanceStatus.leave:
        return 'Izin';
      case _AttendanceStatus.late:
        return 'Terlambat';
      case _AttendanceStatus.absent:
        return 'Tidak Hadir';
    }
  }

  Color get color {
    switch (status) {
      case _AttendanceStatus.present:
        return AppColor.success;
      case _AttendanceStatus.leave:
        return AppColor.warning;
      case _AttendanceStatus.late:
        return AppColor.primary;
      case _AttendanceStatus.absent:
        return AppColor.error;
    }
  }

  IconData get icon {
    switch (status) {
      case _AttendanceStatus.present:
        return Icons.check_circle;
      case _AttendanceStatus.leave:
        return Icons.event_busy;
      case _AttendanceStatus.late:
        return Icons.access_time;
      case _AttendanceStatus.absent:
        return Icons.cancel;
    }
  }
}
