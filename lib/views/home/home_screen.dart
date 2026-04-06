import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/attendance.dart';
import 'package:presenzo_app/services/api/get_user.dart';
import 'package:presenzo_app/views/attendance/attendance_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final Future<GetUserModel?> _profileFuture;
  late final Future<List<_AttendanceHistoryEntry>> _attendanceHistoryFuture;
  Timer? _clockTimer;
  DateTime _currentDateTime = DateTime.now();

  Future<List<_AttendanceHistoryEntry>> _loadRecentHistory() async {
    final today = DateTime.now();
    final endDate = DateTime(today.year, today.month, today.day);
    final startDate = endDate.subtract(const Duration(days: 4));
    final formatter = DateFormat('yyyy-MM-dd');

    final records = await getAttendanceHistory(
      startDate: formatter.format(startDate),
      endDate: formatter.format(endDate),
      limit: 5,
    );

    return records.map(_mapRecordToEntry).toList();
  }

  _AttendanceHistoryEntry _mapRecordToEntry(AttendanceRecord record) {
    final date =
        DateTime.tryParse(record.attendanceDate ?? '') ?? DateTime.now();
    final status = (record.status ?? '').toLowerCase();
    final checkIn = (record.checkInTime ?? '').trim();
    final checkOut = (record.checkOutTime ?? '').trim();
    final reason = (record.alasanIzin ?? '').trim();

    if (status == 'izin') {
      final detail = reason.isEmpty ? 'Izin' : 'Izin - $reason';
      return _AttendanceHistoryEntry(
        date: date,
        status: _AttendanceStatus.leave,
        detail: detail,
      );
    }

    if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
      return _AttendanceHistoryEntry(
        date: date,
        status: _AttendanceStatus.present,
        detail: '$checkIn - $checkOut',
      );
    }

    if (checkIn.isNotEmpty) {
      return _AttendanceHistoryEntry(
        date: date,
        status: _AttendanceStatus.present,
        detail: 'Masuk - $checkIn',
      );
    }

    return _AttendanceHistoryEntry(
      date: date,
      status: _AttendanceStatus.absent,
      detail: 'Tanpa Keterangan',
    );
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
            blurRadius: 16,
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
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(entry.icon, color: entry.color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  entry.detail,
                  style: const TextStyle(
                    fontSize: 11,
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
              borderRadius: BorderRadius.circular(1000),
            ),
            child: Text(
              entry.statusLabel,
              style: TextStyle(
                fontSize: 10,
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
    _attendanceHistoryFuture = _loadRecentHistory();
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
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColor.primary,
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A1D4ED8),
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(Icons.person, color: Colors.white, size: 20),
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

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColor.primary),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Selamat datang',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x120F172A),
                          blurRadius: 16,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat(
                            'EEEE, d MMMM y',
                            'id_ID',
                          ).format(_currentDateTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColor.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('HH:mm:ss').format(_currentDateTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w700,
                          ),
                        ),

                        const SizedBox(height: 16),
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColor.border.withValues(alpha: 0.85),
                        ),
                        const SizedBox(height: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Jam Pelatihan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '08:00 - 15:00',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Aksi Check In')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 7,
                              shadowColor: const Color(0x4D1D4ED8),
                              backgroundColor: AppColor.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.fingerprint, size: 20),
                                SizedBox(width: 8),
                                Text('Absen Masuk'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 64,
                          child: ElevatedButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Aksi Check Out')),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 7,
                              shadowColor: const Color(0x3316A34A),
                              backgroundColor: AppColor.success,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout, size: 20),
                                SizedBox(width: 8),
                                Text('Absen Pulang'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat Kehadiran',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColor.textPrimary,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const AttendanceHistoryScreen(),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Text(
                            'Lihat semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColor.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  FutureBuilder<List<_AttendanceHistoryEntry>>(
                    future: _attendanceHistoryFuture,
                    builder: (context, historySnapshot) {
                      if (historySnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColor.primary,
                            ),
                          ),
                        );
                      }

                      if (historySnapshot.hasError) {
                        return Text(
                          historySnapshot.error.toString(),
                          style: const TextStyle(
                            color: AppColor.error,
                            fontSize: 12,
                          ),
                        );
                      }

                      final attendanceHistory = historySnapshot.data ?? [];
                      if (attendanceHistory.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColor.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColor.border),
                          ),
                          child: const Text(
                            'Belum ada riwayat 5 hari terakhir.',
                            style: TextStyle(
                              color: AppColor.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: [
                          for (
                            var index = 0;
                            index < attendanceHistory.length;
                            index++
                          ) ...[
                            _buildAttendanceItem(attendanceHistory[index]),
                            if (index != attendanceHistory.length - 1)
                              const SizedBox(height: 12),
                          ],
                        ],
                      );
                    },
                  ),
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
