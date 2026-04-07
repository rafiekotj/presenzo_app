import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/services/api/attendance.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/attendance/attendance_detail_screen.dart';

class AttendanceHistoryScreen extends StatefulWidget {
  const AttendanceHistoryScreen({super.key});

  @override
  State<AttendanceHistoryScreen> createState() =>
      _AttendanceHistoryScreenState();
}

class _AttendanceHistoryScreenState extends State<AttendanceHistoryScreen> {
  bool _isLoading = true;
  List<_AttendanceHistoryEntry> _attendanceHistory = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  Future<void> _fetchAttendanceHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Fetch user creation date from storage
      DateTime startDate;
      try {
        final createdAtStr = await PreferenceHandler.getUserCreatedAt();
        if (createdAtStr != null) {
          final parsedDate = DateTime.tryParse(createdAtStr);
          if (parsedDate != null) {
            // Extract date only and set to start of day (00:00:00)
            startDate = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );
          } else {
            startDate = DateTime.now().subtract(const Duration(days: 365));
          }
        } else {
          startDate = DateTime.now().subtract(const Duration(days: 365));
        }
      } catch (_) {
        // Fallback to 1 year ago if storage access fails
        startDate = DateTime.now().subtract(const Duration(days: 365));
      }

      final endDate = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd');
      final records = await getAttendanceHistory(
        startDate: dateFormat.format(startDate),
        endDate: dateFormat.format(endDate),
        limit: -1, // Get all records
      );

      // Get all workdays (Monday-Friday) in the range
      final allWorkdays = _generateAllWorkdays(startDate, endDate);
      final today = DateTime.now();
      final todayStr = dateFormat.format(today);

      // Filter records hanya dari created_at ke depan (client-side filter)
      final filteredRecords = records.where((record) {
        if (record.attendanceDate == null) return false;
        try {
          final recordDate = DateTime.tryParse(record.attendanceDate!);
          if (recordDate != null) {
            // Compare date only (ignore time)
            return recordDate.year > startDate.year ||
                (recordDate.year == startDate.year &&
                    recordDate.month > startDate.month) ||
                (recordDate.year == startDate.year &&
                    recordDate.month == startDate.month &&
                    recordDate.day >= startDate.day);
          }
        } catch (_) {}
        return false;
      }).toList();

      // Update datesWithRecords dengan filtered records
      final filteredDatesWithRecords = filteredRecords
          .map((r) => r.attendanceDate!)
          .toSet();

      // Buat list entries dari filtered records
      final entries = filteredRecords
          .map((record) => _convertToHistoryEntry(record))
          .toList();

      // Tambahkan "tidak hadir" untuk workdays yang tidak ada recordnya
      for (final workday in allWorkdays) {
        final workdayStr = dateFormat.format(workday);
        // Skip hari ini jika belum ada check-in
        if (workdayStr == todayStr) continue;

        if (!filteredDatesWithRecords.contains(workdayStr)) {
          // Buat virtual absent record
          final absentRecord = AttendanceRecord(
            attendanceDate: workdayStr,
            status: 'alpa',
            checkInTime: null,
            checkOutTime: null,
            checkInLat: null,
            checkInLng: null,
            checkOutLat: null,
            checkOutLng: null,
            checkInAddress: null,
            checkOutAddress: null,
            alasanIzin: null,
          );
          entries.add(_convertToHistoryEntry(absentRecord));
        }
      }

      // Sort by date descending (newest first)
      entries.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _attendanceHistory = entries;
        _isLoading = false;
      });
    } catch (e) {
      log('Error fetching attendance history: $e');
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  List<DateTime> _generateAllWorkdays(DateTime start, DateTime end) {
    final workdays = <DateTime>[];
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      // 1 = Monday, 5 = Friday
      if (current.weekday >= 1 && current.weekday <= 5) {
        workdays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return workdays;
  }

  _AttendanceHistoryEntry _convertToHistoryEntry(AttendanceRecord record) {
    final date =
        DateTime.tryParse(record.attendanceDate ?? '') ?? DateTime.now();
    final status = _mapStatusToEnum(record.status);

    String detail = '';
    if (record.status == 'izin') {
      detail = 'Izin - ${record.alasanIzin ?? 'Tidak ada keterangan'}';
    } else if (record.checkInTime != null) {
      detail = 'Masuk - ${record.checkInTime}';
      if (record.checkOutTime != null) {
        detail = 'Keluar - ${record.checkOutTime}';
      }
    } else {
      detail = 'Tanpa Keterangan';
    }

    return _AttendanceHistoryEntry(
      date: date,
      status: status,
      detail: detail,
      record: record,
    );
  }

  _AttendanceStatus _mapStatusToEnum(String? status) {
    switch (status?.toLowerCase()) {
      case 'masuk':
        return _AttendanceStatus.present;
      case 'izin':
        return _AttendanceStatus.leave;
      case 'terlambat':
        return _AttendanceStatus.late;
      case 'tidak hadir':
      case 'alpa':
        return _AttendanceStatus.absent;
      default:
        return _AttendanceStatus.absent;
    }
  }

  Widget _buildAttendanceItem(_AttendanceHistoryEntry entry) {
    final formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'id_ID',
    ).format(entry.date);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.of(context).push<bool>(
          MaterialPageRoute(
            builder: (_) => AttendanceDetailScreen(record: entry.record),
          ),
        );

        if (result == true) {
          await _fetchAttendanceHistory();
        }
      },
      child: Container(
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
      ),
    );
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
        title: const Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColor.primary),
            )
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColor.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchAttendanceHistory,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            )
          : _attendanceHistory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 48,
                    color: AppColor.textSecondary.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Tidak ada data riwayat kehadiran',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _attendanceHistory.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _buildAttendanceItem(_attendanceHistory[index]),
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
    required this.record,
  });

  final DateTime date;
  final _AttendanceStatus status;
  final String detail;
  final AttendanceRecord record;

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
        return AppColor.secondary;
      case _AttendanceStatus.absent:
        return AppColor.error;
    }
  }

  IconData get icon {
    switch (status) {
      case _AttendanceStatus.present:
        return Icons.check_circle_rounded;
      case _AttendanceStatus.leave:
        return Icons.event_busy_rounded;
      case _AttendanceStatus.late:
        return Icons.schedule_rounded;
      case _AttendanceStatus.absent:
        return Icons.cancel_rounded;
    }
  }
}
