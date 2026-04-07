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

  @override
  void initState() {
    super.initState();
    HomeScreen._stateInstance = this;
    WidgetsBinding.instance.addObserver(this);
    _initializeFutures();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _currentDateTime = DateTime.now();
      });
    });
  }

  void _initializeFutures() {
    _profileFuture = getUser();
    _attendanceHistoryFuture = _loadRecentHistory();
    _attendanceStatsFuture = _loadAttendanceStats();
    final today = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    _todayAttendanceFuture = getTodayAttendance(
      attendanceDate: dateFormatter.format(today),
    );
  }

  void _refresh() {
    if (!mounted || _isRefreshing) return;

    // Cancel previous debounce timer
    _refreshDebounceTimer?.cancel();

    // Debounce: wait 500ms before refreshing to avoid rapid multiple refreshes
    _refreshDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _isRefreshing = true;
        _initializeFutures();
      });
      // Reset refresh flag after a delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
          });
        }
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  void _refreshAttendanceData() {
    if (!mounted) return;
    final today = DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');
    setState(() {
      _attendanceHistoryFuture = _loadRecentHistory();
      _attendanceStatsFuture = _loadAttendanceStats();
      _todayAttendanceFuture = getTodayAttendance(
        attendanceDate: dateFormatter.format(today),
      );
    });
  }

  Future<List<_AttendanceHistoryEntry>> _loadRecentHistory() async {
    try {
      final today = DateTime.now();
      final endDate = DateTime(today.year, today.month, today.day);

      // Fetch user creation date from storage
      DateTime startDate;
      try {
        final createdAtStr = await PreferenceHandler.getUserCreatedAt();
        if (createdAtStr != null) {
          final parsedDate = DateTime.tryParse(createdAtStr);
          if (parsedDate != null) {
            // Extract date only (ignore timezone, use date part)
            final createdDate = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );
            // Calculate days since account creation
            final daysSinceCreation = endDate.difference(createdDate).inDays;
            // Show max 5 most recent days, or fewer if account is newer
            final daysToShow = daysSinceCreation < 5 ? daysSinceCreation : 4;
            startDate = endDate.subtract(Duration(days: daysToShow));
          } else {
            startDate = endDate.subtract(const Duration(days: 4));
          }
        } else {
          startDate = endDate.subtract(const Duration(days: 4));
        }
      } catch (_) {
        // Fallback to recent 5 days if storage access fails
        startDate = endDate.subtract(const Duration(days: 4));
      }

      final formatter = DateFormat('yyyy-MM-dd');

      final records = await getAttendanceHistory(
        startDate: formatter.format(startDate),
        endDate: formatter.format(endDate),
        limit: 5,
      );

      // Get all workdays in the range
      final allWorkdays = _generateRecentWorkdays(startDate, endDate);

      // Get created date for filtering
      DateTime? createdDate;
      try {
        final createdAtStr = await PreferenceHandler.getUserCreatedAt();
        if (createdAtStr != null) {
          final parsedDate = DateTime.tryParse(createdAtStr);
          if (parsedDate != null) {
            createdDate = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );
          }
        }
      } catch (_) {}

      // Filter records hanya dari created_at ke depan (client-side filter)
      final filteredRecords = records.where((record) {
        if (record.attendanceDate == null) return false;
        if (createdDate == null) return true;
        try {
          final recordDate = DateTime.tryParse(record.attendanceDate!);
          if (recordDate != null) {
            // Compare date only (ignore time)
            return recordDate.year > createdDate.year ||
                (recordDate.year == createdDate.year &&
                    recordDate.month > createdDate.month) ||
                (recordDate.year == createdDate.year &&
                    recordDate.month == createdDate.month &&
                    recordDate.day >= createdDate.day);
          }
        } catch (_) {}
        return false;
      }).toList();

      // Get set of dates yang ada recordnya
      final datesWithRecords = filteredRecords
          .map((r) => r.attendanceDate!)
          .toSet();

      // Buat list entries dari filtered records
      final entries = filteredRecords.map(_mapRecordToEntry).toList();

      // Get today date string (using endDate since today is already defined as it)
      final todayStr = formatter.format(endDate);

      // Tambahkan "tidak hadir" untuk workdays yang tidak ada recordnya
      for (final workday in allWorkdays) {
        final workdayStr = formatter.format(workday);
        // Skip hari ini jika belum ada check-in
        if (workdayStr == todayStr) continue;

        if (!datesWithRecords.contains(workdayStr)) {
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
          entries.add(_mapRecordToEntry(absentRecord));
        }
      }

      // Sort by date descending (newest first)
      entries.sort((a, b) => b.date.compareTo(a.date));

      return entries;
    } catch (e) {
      // Gracefully handle network errors
      return [];
    }
  }

  Future<AttendanceStatsResponse> _loadAttendanceStats() async {
    try {
      final today = DateTime.now();
      final endDate = DateTime(today.year, today.month, today.day);

      // Fetch user creation date from storage
      DateTime startDate;
      try {
        final createdAtStr = await PreferenceHandler.getUserCreatedAt();
        if (createdAtStr != null) {
          final parsedDate = DateTime.tryParse(createdAtStr);
          if (parsedDate != null) {
            startDate = DateTime(
              parsedDate.year,
              parsedDate.month,
              parsedDate.day,
            );
          } else {
            startDate = endDate.subtract(const Duration(days: 365));
          }
        } else {
          startDate = endDate.subtract(const Duration(days: 365));
        }
      } catch (_) {
        startDate = endDate.subtract(const Duration(days: 365));
      }

      final formatter = DateFormat('yyyy-MM-dd');
      return getAttendanceStats(
        startDate: formatter.format(startDate),
        endDate: formatter.format(endDate),
      );
    } catch (e) {
      throw Exception('Failed to load attendance stats: $e');
    }
  }

  List<DateTime> _generateRecentWorkdays(DateTime start, DateTime end) {
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
      // Check if check-in is after 08:00:00
      final isLate = _isCheckInLate(checkIn);
      return _AttendanceHistoryEntry(
        date: date,
        status: isLate ? _AttendanceStatus.late : _AttendanceStatus.present,
        detail: '$checkIn - $checkOut',
        record: record,
      );
    }

    if (checkIn.isNotEmpty) {
      // Check if check-in is after 08:00:00
      final isLate = _isCheckInLate(checkIn);
      return _AttendanceHistoryEntry(
        date: date,
        status: isLate ? _AttendanceStatus.late : _AttendanceStatus.present,
        detail: 'Masuk - $checkIn',
        record: record,
      );
    }

    // Default: tidak hadir (absent)
    return _AttendanceHistoryEntry(
      date: date,
      status: _AttendanceStatus.absent,
      detail: 'Tanpa Keterangan',
      record: record,
    );
  }

  bool _isCheckInLate(String checkInTime) {
    try {
      // Parse time format HH:mm:ss or HH:mm
      final parts = checkInTime.split(':');
      if (parts.length < 2) return false;

      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;

      // 08:00:00 = jam 8 pagi, jadi late jika > 08:00
      return hour > 8 || (hour == 8 && minute > 0);
    } catch (_) {
      return false;
    }
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

  Widget _buildAttendanceItem(_AttendanceHistoryEntry entry) {
    final formattedDate = DateFormat(
      'EEEE, d MMMM y',
      'id_ID',
    ).format(entry.date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AttendanceDetailScreen(record: entry.record),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: entry.color.withValues(alpha: 0.1),
            width: 1.5,
          ),
          boxShadow: [
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
                border: Border.all(color: entry.color.withValues(alpha: 0.2)),
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
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.detail,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: entry.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: entry.color.withValues(alpha: 0.2)),
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
  }

  Widget _buildStatCard({
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        height: 115,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColor.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: color,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColor.textSecondary,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clockTimer?.cancel();
    _refreshDebounceTimer?.cancel();
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
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Sistem Presensi Digital',
              style: TextStyle(
                color: AppColor.textSecondary.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.3,
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
                          color: Colors.white,
                          size: 20,
                        )
                      : null,
                );
              },
            ),
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
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                          ),
                          child: const Icon(
                            Icons.school_rounded,
                            color: Colors.white,
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
                                  color: Colors.white.withValues(alpha: 0.85),
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
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
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
                      color: Colors.white,
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
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          DateFormat('HH:mm:ss').format(_currentDateTime),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColor.textPrimary,
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColor.border.withValues(alpha: 0),
                                AppColor.border.withValues(alpha: 0.4),
                                AppColor.border.withValues(alpha: 0),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Jam Pelatihan',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColor.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '08:00 - 15:00',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
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
                  const SizedBox(height: 16),
                  FutureBuilder<AttendanceApiResponse>(
                    future: _todayAttendanceFuture,
                    builder: (context, attendanceSnapshot) {
                      final hasCheckIn =
                          (attendanceSnapshot.data?.data?.checkInTime ?? '')
                              .trim()
                              .isNotEmpty;
                      final hasCheckOut =
                          (attendanceSnapshot.data?.data?.checkOutTime ?? '')
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
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(
                                      color: isCheckInEnabled
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.transparent,
                                    ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.fingerprint,
                                      size: 22,
                                      color: isCheckInEnabled
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Absen Masuk',
                                      style: TextStyle(
                                        color: isCheckInEnabled
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
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
                                      ? const Color(0x3316A34A)
                                      : Colors.transparent,
                                  backgroundColor: isCheckOutEnabled
                                      ? AppColor.success
                                      : AppColor.textSecondary.withValues(
                                          alpha: 0.3,
                                        ),
                                  foregroundColor: isCheckOutEnabled
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                    side: BorderSide(
                                      color: isCheckOutEnabled
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : Colors.transparent,
                                    ),
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
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout,
                                      size: 22,
                                      color: isCheckOutEnabled
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      'Absen Pulang',
                                      style: TextStyle(
                                        color: isCheckOutEnabled
                                            ? Colors.white
                                            : Colors.white.withValues(
                                                alpha: 0.5,
                                              ),
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
                  const SizedBox(height: 16),
                  // Attendance Statistics Section
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: AppColor.primary,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Statistik Absensi',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildStatCard(
                                label: 'Hadir',
                                count: stats.totalMasuk,
                                color: AppColor.success,
                              ),
                              const SizedBox(width: 12),
                              _buildStatCard(
                                label: 'Izin',
                                count: stats.totalIzin,
                                color: AppColor.warning,
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColor.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 12),
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
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColor.border.withValues(alpha: 0.4),
                            ),
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
                            _buildAttendanceItem(attendanceHistory[index]),
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
        return Icons.access_time;
      case _AttendanceStatus.absent:
        return Icons.cancel;
    }
  }
}
