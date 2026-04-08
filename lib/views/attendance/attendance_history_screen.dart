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

  // Menjalankan pemuatan data riwayat saat halaman pertama kali dibuka.
  @override
  void initState() {
    super.initState();
    _fetchAttendanceHistory();
  }

  // Memuat data riwayat absensi lengkap lalu memperbarui state tampilan.
  Future<void> _fetchAttendanceHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final startDate = await _resolveHistoryStartDate();
      final endDate = DateTime.now();
      final dateFormat = DateFormat('yyyy-MM-dd');

      final records = await getAttendanceHistory(
        startDate: dateFormat.format(startDate),
        endDate: dateFormat.format(endDate),
        limit: -1,
      );

      final filteredRecords = _filterRecordsFromStartDate(records, startDate);
      final allWorkdays = _generateAllWorkdays(startDate, endDate);
      final entries = _buildHistoryEntriesWithVirtualAbsents(
        filteredRecords: filteredRecords,
        allWorkdays: allWorkdays,
        endDate: endDate,
        dateFormat: dateFormat,
      );

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

  // Menentukan tanggal mulai riwayat berdasarkan tanggal pembuatan akun.
  Future<DateTime> _resolveHistoryStartDate() async {
    try {
      final createdAtStr = await PreferenceHandler.getUserCreatedAt();
      final parsedDate = createdAtStr == null
          ? null
          : DateTime.tryParse(createdAtStr);
      if (parsedDate == null) {
        return DateTime.now().subtract(const Duration(days: 365));
      }

      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } catch (_) {
      return DateTime.now().subtract(const Duration(days: 365));
    }
  }

  // Menyaring record agar hanya data valid setelah tanggal mulai yang dipakai.
  List<AttendanceRecord> _filterRecordsFromStartDate(
    List<AttendanceRecord> records,
    DateTime startDate,
  ) {
    return records.where((record) {
      if (record.attendanceDate == null) return false;

      final recordDate = DateTime.tryParse(record.attendanceDate!);
      if (recordDate == null) return false;

      return _isOnOrAfterDate(recordDate, startDate);
    }).toList();
  }

  // Menyusun entri riwayat dan menambahkan entri alpa virtual untuk hari kosong.
  List<_AttendanceHistoryEntry> _buildHistoryEntriesWithVirtualAbsents({
    required List<AttendanceRecord> filteredRecords,
    required List<DateTime> allWorkdays,
    required DateTime endDate,
    required DateFormat dateFormat,
  }) {
    final entries = filteredRecords
        .map((record) => _convertToHistoryEntry(record))
        .toList();

    final datesWithRecords = filteredRecords
        .map((record) => record.attendanceDate!)
        .toSet();
    final todayStr = dateFormat.format(endDate);

    for (final workday in allWorkdays) {
      final workdayStr = dateFormat.format(workday);

      if (workdayStr == todayStr) continue;
      if (datesWithRecords.contains(workdayStr)) continue;

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

    return entries;
  }

  // Membandingkan dua tanggal dengan presisi tahun-bulan-hari.
  bool _isOnOrAfterDate(DateTime date, DateTime targetDate) {
    return date.year > targetDate.year ||
        (date.year == targetDate.year && date.month > targetDate.month) ||
        (date.year == targetDate.year &&
            date.month == targetDate.month &&
            date.day >= targetDate.day);
  }

  // Menghasilkan daftar hari kerja (Senin sampai Jumat) pada rentang tanggal.
  List<DateTime> _generateAllWorkdays(DateTime start, DateTime end) {
    final workdays = <DateTime>[];
    var current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (current.weekday >= 1 && current.weekday <= 5) {
        workdays.add(current);
      }
      current = current.add(const Duration(days: 1));
    }

    return workdays;
  }

  // Mengubah record absensi mentah menjadi model entri untuk UI riwayat.
  _AttendanceHistoryEntry _convertToHistoryEntry(AttendanceRecord record) {
    final date =
        DateTime.tryParse(record.attendanceDate ?? '') ?? DateTime.now();
    var status = _mapStatusToEnum(record.status);

    String detail = '';
    if (record.status == 'izin') {
      detail = 'Izin - ${record.alasanIzin ?? 'Tidak ada keterangan'}';
    } else if (record.checkInTime != null) {
      if (record.status == 'masuk' && _isCheckInLate(record.checkInTime!)) {
        status = _AttendanceStatus.late;
      }

      if (record.checkOutTime != null) {
        detail = '${record.checkInTime} - ${record.checkOutTime}';
      } else {
        detail = 'Masuk - ${record.checkInTime}';
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

  // Memetakan status string dari API ke enum status lokal.
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

  // Mengecek apakah waktu check-in melewati batas 08:00.
  bool _isCheckInLate(String checkInTime) {
    try {
      final parts = checkInTime.split(':');
      if (parts.length < 2) return false;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      return hour > 8 || (hour == 8 && minute > 0);
    } catch (_) {
      return false;
    }
  }

  // Membangun tampilan utama halaman riwayat kehadiran.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: true,
        title: Text(
          'Riwayat Kehadiran',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
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
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppColor.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Gagal memuat data',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _fetchAttendanceHistory,
                    child: Text('Coba Lagi'),
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tidak ada data riwayat kehadiran',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: _attendanceHistory.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = _attendanceHistory[index];
                final formattedDate = DateFormat(
                  'EEEE, d MMMM y',
                  'id_ID',
                ).format(entry.date);

                return GestureDetector(
                  onTap: () async {
                    final result = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(
                        builder: (_) =>
                            AttendanceDetailScreen(record: entry.record),
                      ),
                    );

                    if (result == true) {
                      await _fetchAttendanceHistory();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: Theme.of(context).brightness == Brightness.dark ? const [] : [
                        BoxShadow(
                          color: entry.color.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: entry.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(entry.icon, color: entry.color, size: 26),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Theme.of(context).colorScheme.onSurface,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                entry.detail,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: entry.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            entry.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: entry.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
        return AppColor.success;
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
        return Icons.check_circle;
      case _AttendanceStatus.absent:
        return Icons.cancel;
    }
  }
}






