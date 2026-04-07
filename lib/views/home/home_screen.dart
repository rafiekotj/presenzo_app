import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/attendance.dart';
import 'package:presenzo_app/services/api/get_user.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/attendance/attendance_detail_screen.dart';
import 'package:presenzo_app/views/attendance/attendance_history_screen.dart';
import 'package:presenzo_app/views/attendance/attendance_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static late _HomeScreenState _stateInstance;

  static void refresh() {
    _stateInstance._refresh();
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late Future<GetUserModel?> _profileFuture;
  late Future<List<_AttendanceHistoryEntry>> _attendanceHistoryFuture;
  late Future<AttendanceApiResponse> _todayAttendanceFuture;
  late Future<AttendanceStatsResponse> _attendanceStatsFuture;
  Timer? _clockTimer;
  Timer? _refreshDebounceTimer;
  DateTime _currentDateTime = DateTime.now();
  bool _isRefreshing = false;

  // Inisialisasi observer, future, dan pembaruan jam real-time.
  @override
  void initState() {
    super.initState();
    HomeScreen._stateInstance = this;
    WidgetsBinding.instance.addObserver(this);
    _loadHomeFutures(includeProfile: true);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  // Memuat ulang data saat aplikasi kembali ke foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  // Membersihkan timer dan observer lifecycle.
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _refreshDebounceTimer?.cancel();
    super.dispose();
  }

  // Memuat future untuk profil, riwayat, statistik, dan absensi hari ini.
  void _loadHomeFutures({bool includeProfile = false}) {
    if (includeProfile) {
      _profileFuture = getUser();
    }

    _attendanceHistoryFuture = _loadRecentHistory();
    _attendanceStatsFuture = _loadAttendanceStats();
    final today = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    _todayAttendanceFuture = getTodayAttendance(
      attendanceDate: dateFormatter.format(today),
    );
  }

  // Melakukan debounce lalu memicu refresh penuh data home.
  void _refresh() {
    if (!mounted || _isRefreshing) return;

    _refreshDebounceTimer?.cancel();

    _refreshDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isRefreshing = true;
        _loadHomeFutures(includeProfile: true);
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    });
  }

  // Memuat ulang future yang terkait absensi saja.
  void _refreshAttendanceData() {
    if (!mounted) return;
    setState(() {
      _loadHomeFutures();
    });
  }

  // Memuat riwayat absensi terbaru dan menambahkan alpa untuk hari kerja yang kosong.
  Future<List<_AttendanceHistoryEntry>> _loadRecentHistory() async {
    try {
      final today = DateTime.now();
      final endDate = DateTime(today.year, today.month, today.day);
      final startDate = await _resolveHistoryStartDate(endDate);
      final records = await _fetchHistoryRecords(startDate, endDate);
      final allWorkdays = _generateRecentWorkdays(startDate, endDate);
      final createdDate = await _getUserCreatedDate();

      final filteredRecords = _filterRecordsAfterCreatedDate(
        records,
        createdDate,
      );

      final entries = filteredRecords.map(_mapRecordToEntry).toList();
      _appendVirtualAbsentEntries(
        entries: entries,
        filteredRecords: filteredRecords,
        allWorkdays: allWorkdays,
        endDate: endDate,
      );

      entries.sort((a, b) => b.date.compareTo(a.date));

      return entries;
    } catch (e) {
      return [];
    }
  }

  // Memuat statistik absensi dari tanggal akun dibuat sampai hari ini.
  Future<AttendanceStatsResponse> _loadAttendanceStats() async {
    try {
      final today = DateTime.now();
      final endDate = DateTime(today.year, today.month, today.day);
      final startDate = await _resolveStatsStartDate(endDate);

      final formatter = DateFormat('yyyy-MM-dd');
      return getAttendanceStats(
        startDate: formatter.format(startDate),
        endDate: formatter.format(endDate),
      );
    } catch (e) {
      throw Exception('Failed to load attendance stats: $e');
    }
  }

  // Menentukan tanggal mulai untuk tampilan riwayat singkat.
  Future<DateTime> _resolveHistoryStartDate(DateTime endDate) async {
    final createdDate = await _getUserCreatedDate();
    if (createdDate == null) {
      return endDate.subtract(const Duration(days: 4));
    }

    final daysSinceCreation = endDate.difference(createdDate).inDays;
    final daysToShow = daysSinceCreation < 5 ? daysSinceCreation : 4;
    return endDate.subtract(Duration(days: daysToShow));
  }

  // Menentukan tanggal mulai untuk perhitungan statistik.
  Future<DateTime> _resolveStatsStartDate(DateTime endDate) async {
    final createdDate = await _getUserCreatedDate();
    if (createdDate != null) return createdDate;
    return endDate.subtract(const Duration(days: 365));
  }

  // Mengambil dan menormalkan tanggal akun dibuat.
  Future<DateTime?> _getUserCreatedDate() async {
    try {
      final createdAtStr = await PreferenceHandler.getUserCreatedAt();
      final parsedDate = createdAtStr == null
          ? null
          : DateTime.tryParse(createdAtStr);
      if (parsedDate == null) return null;
      return DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
    } catch (_) {
      return null;
    }
  }

  // Mengambil data mentah riwayat absensi pada rentang tanggal.
  Future<List<AttendanceRecord>> _fetchHistoryRecords(
    DateTime startDate,
    DateTime endDate,
  ) {
    final formatter = DateFormat('yyyy-MM-dd');
    return getAttendanceHistory(
      startDate: formatter.format(startDate),
      endDate: formatter.format(endDate),
      limit: 5,
    );
  }

  // Menyaring record agar hanya tanggal setelah akun dibuat yang dipakai.
  List<AttendanceRecord> _filterRecordsAfterCreatedDate(
    List<AttendanceRecord> records,
    DateTime? createdDate,
  ) {
    return records.where((record) {
      if (record.attendanceDate == null) return false;
      if (createdDate == null) return true;

      final recordDate = DateTime.tryParse(record.attendanceDate!);
      if (recordDate == null) return false;

      return _isOnOrAfterDate(recordDate, createdDate);
    }).toList();
  }

  // Membandingkan dua tanggal pada presisi tahun-bulan-hari.
  bool _isOnOrAfterDate(DateTime date, DateTime referenceDate) {
    return date.year > referenceDate.year ||
        (date.year == referenceDate.year && date.month > referenceDate.month) ||
        (date.year == referenceDate.year &&
            date.month == referenceDate.month &&
            date.day >= referenceDate.day);
  }

  // Menambahkan entri alpa virtual untuk hari kerja tanpa record.
  void _appendVirtualAbsentEntries({
    required List<_AttendanceHistoryEntry> entries,
    required List<AttendanceRecord> filteredRecords,
    required List<DateTime> allWorkdays,
    required DateTime endDate,
  }) {
    final formatter = DateFormat('yyyy-MM-dd');
    final todayStr = formatter.format(endDate);
    final datesWithRecords = filteredRecords
        .map((record) => record.attendanceDate!)
        .toSet();

    for (final workday in allWorkdays) {
      final workdayStr = formatter.format(workday);
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
      entries.add(_mapRecordToEntry(absentRecord));
    }
  }

  // Menghasilkan daftar hari kerja antara tanggal mulai dan akhir.
  List<DateTime> _generateRecentWorkdays(DateTime start, DateTime end) {
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

  // Memetakan record absensi dari API menjadi entri riwayat untuk UI.
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
        record: record,
      );
    }

    if (checkIn.isNotEmpty && checkOut.isNotEmpty) {
      final isLate = _isCheckInLate(checkIn);
      return _AttendanceHistoryEntry(
        date: date,
        status: isLate ? _AttendanceStatus.late : _AttendanceStatus.present,
        detail: '$checkIn - $checkOut',
        record: record,
      );
    }

    if (checkIn.isNotEmpty) {
      final isLate = _isCheckInLate(checkIn);
      return _AttendanceHistoryEntry(
        date: date,
        status: isLate ? _AttendanceStatus.late : _AttendanceStatus.present,
        detail: 'Masuk - $checkIn',
        record: record,
      );
    }

    return _AttendanceHistoryEntry(
      date: date,
      status: _AttendanceStatus.absent,
      detail: 'Tanpa Keterangan',
      record: record,
    );
  }

  // Menentukan apakah jam check-in lebih dari 08:00.
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

  // Membangun image provider avatar dari URL atau sumber base64.
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

  // Membangun tampilan halaman home.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColor.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        centerTitle: false,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Presenzo',
              style: TextStyle(
                color: AppColor.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColor.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: AppColor.surface.withValues(alpha: 0.1),
              ),
            ),
            child: FutureBuilder<GetUserModel?>(
              future: _profileFuture,
              builder: (context, snapshot) {
                final photoUrl = snapshot.data?.data?.photoUrl;
                final avatarProvider = _buildAvatarProvider(photoUrl);

                return CircleAvatar(
                  backgroundColor: AppColor.primary,
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? const Icon(
                          Icons.person_rounded,
                          color: AppColor.surface,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
      body: FutureBuilder<GetUserModel?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          final profileName = snapshot.data?.data?.name?.trim();
          final displayName = (profileName == null || profileName.isEmpty)
              ? 'Pengguna'
              : profileName;

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColor.primary,
                        AppColor.primary.withValues(alpha: 0.85),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withValues(alpha: 0.25),
                        blurRadius: 28,
                        offset: const Offset(0, 12),
                      ),
                    ],
                    border: Border.all(
                      color: AppColor.surface.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColor.surface.withValues(alpha: 0.18),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColor.surface.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.school_rounded,
                          color: AppColor.surface,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Selamat datang',
                              style: TextStyle(
                                color: AppColor.surface.withValues(alpha: 0.85),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColor.surface,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
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
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primary.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                    border: Border.all(
                      color: AppColor.primary.withValues(alpha: 0.05),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        DateFormat('HH:mm').format(_currentDateTime),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColor.secondary,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<AttendanceApiResponse>(
                        future: _todayAttendanceFuture,
                        builder: (context, attendanceSnapshot) {
                          final hasCheckIn =
                              (attendanceSnapshot.data?.data?.checkInTime ?? '')
                                  .trim()
                                  .isNotEmpty;
                          final hasCheckOut =
                              (attendanceSnapshot.data?.data?.checkOutTime ??
                                      '')
                                  .trim()
                                  .isNotEmpty;

                          final isCheckInEnabled =
                              !hasCheckIn &&
                              attendanceSnapshot.connectionState ==
                                  ConnectionState.done;
                          final isCheckOutEnabled =
                              hasCheckIn &&
                              !hasCheckOut &&
                              attendanceSnapshot.connectionState ==
                                  ConnectionState.done;

                          return Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 64,
                                  child: ElevatedButton(
                                    onPressed: isCheckInEnabled
                                        ? () async {
                                            final result =
                                                await Navigator.of(
                                                  context,
                                                ).push<bool>(
                                                  MaterialPageRoute<bool>(
                                                    builder: (_) =>
                                                        const AttendanceScreen(),
                                                  ),
                                                );
                                            if (result == true) {
                                              _refreshAttendanceData();
                                            }
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      elevation: isCheckInEnabled ? 8 : 0,
                                      shadowColor: isCheckInEnabled
                                          ? const Color(0x4D1D4ED8)
                                          : Colors.transparent,
                                      backgroundColor: isCheckInEnabled
                                          ? AppColor.primary
                                          : AppColor.textSecondary.withValues(
                                              alpha: 0.3,
                                            ),
                                      foregroundColor: isCheckInEnabled
                                          ? AppColor.surface
                                          : AppColor.surface.withValues(
                                              alpha: 0.5,
                                            ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.fingerprint,
                                          size: 20,
                                          color: isCheckInEnabled
                                              ? AppColor.surface
                                              : AppColor.textPrimary.withValues(
                                                  alpha: 0.4,
                                                ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Absen Masuk',
                                          style: TextStyle(
                                            color: isCheckInEnabled
                                                ? AppColor.surface
                                                : AppColor.textPrimary
                                                      .withValues(alpha: 0.4),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: SizedBox(
                                  height: 64,
                                  child: ElevatedButton(
                                    onPressed: isCheckOutEnabled
                                        ? () async {
                                            final result =
                                                await Navigator.of(
                                                  context,
                                                ).push<bool>(
                                                  MaterialPageRoute<bool>(
                                                    builder: (_) =>
                                                        const AttendanceScreen(),
                                                  ),
                                                );
                                            if (result == true) {
                                              _refreshAttendanceData();
                                            }
                                          }
                                        : null,
                                    style: ElevatedButton.styleFrom(
                                      elevation: isCheckOutEnabled ? 8 : 0,
                                      shadowColor: isCheckOutEnabled
                                          ? const Color(0x4D1D4ED8)
                                          : Colors.transparent,
                                      backgroundColor: isCheckOutEnabled
                                          ? AppColor.primary
                                          : AppColor.textSecondary.withValues(
                                              alpha: 0.3,
                                            ),
                                      foregroundColor: isCheckOutEnabled
                                          ? AppColor.surface
                                          : AppColor.surface.withValues(
                                              alpha: 0.5,
                                            ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 12,
                                      ),
                                      textStyle: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.logout,
                                          size: 20,
                                          color: isCheckOutEnabled
                                              ? AppColor.surface
                                              : AppColor.textPrimary.withValues(
                                                  alpha: 0.4,
                                                ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          'Absen Pulang',
                                          style: TextStyle(
                                            color: isCheckOutEnabled
                                                ? AppColor.surface
                                                : AppColor.textPrimary
                                                      .withValues(alpha: 0.4),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColor.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.access_time,
                          color: AppColor.primary,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jam Pelatihan',
                            style: TextStyle(
                              color: AppColor.primary.withValues(alpha: 0.9),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            '08:00 - 15:00',
                            style: TextStyle(
                              color: AppColor.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Statistik Absensi',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColor.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<AttendanceStatsResponse>(
                  future: _attendanceStatsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const SizedBox.shrink();
                    }

                    final stats = snapshot.data!.data;
                    return Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.secondary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'HADIR',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.surface,
                                    letterSpacing: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  stats.totalMasuk.toString(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.surface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: AppColor.warning.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'IZIN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColor.textPrimary,
                                    letterSpacing: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  stats.totalIzin.toString(),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'Riwayat Kehadiran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
                        child: const Text(
                          'Lihat Riwayat',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColor.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<List<_AttendanceHistoryEntry>>(
                  future: _attendanceHistoryFuture,
                  builder: (context, historySnapshot) {
                    if (historySnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColor.primary,
                            strokeWidth: 2.5,
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
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColor.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColor.primary.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColor.textSecondary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.event_note_outlined,
                                color: AppColor.textSecondary.withValues(
                                  alpha: 0.5,
                                ),
                                size: 28,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada riwayat 5 hari terakhir',
                              style: TextStyle(
                                color: AppColor.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
                          Builder(
                            builder: (context) {
                              final entry = attendanceHistory[index];
                              final formattedDate = DateFormat(
                                'EEEE, d MMMM y',
                                'id_ID',
                              ).format(entry.date);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AttendanceDetailScreen(
                                        record: entry.record,
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColor.surface,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: entry.color.withValues(
                                          alpha: 0.05,
                                        ),
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
                                          color: entry.color.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        child: Icon(
                                          entry.icon,
                                          color: entry.color,
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                                color: AppColor.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              entry.detail,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: AppColor.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: entry.color.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
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
                            },
                          ),
                          if (index != attendanceHistory.length - 1)
                            const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
                if (snapshot.hasError) ...[
                  const SizedBox(height: 8),
                  Text(
                    snapshot.error.toString(),
                    style: const TextStyle(color: AppColor.error, fontSize: 12),
                  ),
                ],
              ],
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
