import 'dart:async';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/services/api/attendance.dart';
import 'package:presenzo_app/services/storage/preference.dart';
import 'package:presenzo_app/views/home/home_screen.dart';
import 'package:presenzo_app/widgets/custom_text_field.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  static const double _checkInTargetLat = -6.2110317;
  static const double _checkInTargetLng = 106.8126051;
  static const double _maxCheckInDistanceMeters = 50;
  static const int _checkInStartHour = 5;
  static const int _checkOutStartHour = 15;
  static const int _autoCheckOutHour = 17;

  final TextEditingController _reasonController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');

  Timer? _clockTimer;
  final ValueNotifier<DateTime> _nowNotifier = ValueNotifier(DateTime.now());

  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = 'Lokasi belum tersedia';

  AttendanceRecord? _todayAttendance;
  bool _hasTodayAttendance = false;
  bool _canCheckoutToday = false;
  bool _isIzinToday = false;
  bool _isAttendanceCompletedToday = false;

  bool _isLoading = true;
  bool _isMapReady = false;
  bool _isLocationLoading = false;
  bool _isSubmitting = false;
  bool _isAutoCheckoutRunning = false;

  AttendanceMode _selectedMode = AttendanceMode.hadir;

  @override
  // Menyiapkan jam berjalan dan memulai pemuatan data awal saat layar dibuka.
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _nowNotifier.value = DateTime.now();
    });
    _loadInitialData();
  }

  // Mengambil token aktif untuk kebutuhan debugging saat layar dibuka.
  Future<void> _logActiveToken() async {
    final token = await PreferenceHandler.getToken();
    log('active_user_token=$token');
  }

  @override
  // Membersihkan controller, timer, dan map controller saat layar ditutup.
  void dispose() {
    _reasonController.dispose();
    _mapController?.dispose();
    _clockTimer?.cancel();
    _nowNotifier.dispose();
    super.dispose();
  }

  // Menjalankan alur awal halaman: token, lokasi, dan status presensi hari ini.
  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
    });

    unawaited(_logActiveToken());
    await _fetchTodayAttendance();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    // Lokasi dan reverse geocoding dijalankan di belakang layar agar layar cepat muncul.
    unawaited(_fetchCurrentLocation());
  }

  // Mengambil data presensi hari ini lalu menerapkan semua flag status ke state.
  Future<void> _fetchTodayAttendance() async {
    final attendanceDate = _dateFormat.format(DateTime.now());
    AttendanceRecord? todayAttendance;

    try {
      final todayResponse = await getTodayAttendance(
        attendanceDate: attendanceDate,
      );
      todayAttendance = todayResponse.data;
    } catch (_) {
      todayAttendance = null;
    }

    _applyAttendanceFlags(todayAttendance);
    unawaited(_tryAutoCheckoutIfNeeded());
  }

  // Menurunkan seluruh kondisi UI dari data presensi hari ini agar alurnya satu pintu.
  void _applyAttendanceFlags(AttendanceRecord? todayAttendance) {
    if (!mounted) return;

    final status = (todayAttendance?.status ?? '').toLowerCase();
    final hasCheckIn = (todayAttendance?.checkInTime ?? '').trim().isNotEmpty;
    final hasCheckOut = (todayAttendance?.checkOutTime ?? '').trim().isNotEmpty;
    final hasTodayAttendance = todayAttendance != null;
    final isIzinToday = status == 'izin';
    final canCheckoutToday =
        hasTodayAttendance && hasCheckIn && !hasCheckOut && !isIzinToday;
    final isAttendanceCompletedToday =
        isIzinToday || (hasCheckIn && hasCheckOut);

    setState(() {
      _todayAttendance = todayAttendance;
      _hasTodayAttendance = hasTodayAttendance;
      _canCheckoutToday = canCheckoutToday;
      _isIzinToday = isIzinToday;
      _isAttendanceCompletedToday = isAttendanceCompletedToday;
    });
  }

  // Mengambil lokasi pengguna, mengubahnya menjadi alamat, lalu memusatkan peta.
  Future<void> _fetchCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isLocationLoading = true;
      });
    }

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Layanan lokasi belum aktif.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
        ),
        timeLimit: const Duration(seconds: 5),
      );

      String address =
          'Lat ${position.latitude.toStringAsFixed(6)}, Lng ${position.longitude.toStringAsFixed(6)}';

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _currentAddress = address;
      });

      await _focusMapToPosition(position);
      unawaited(_resolveAddress(position));
    } catch (error) {
      _showErrorMessage(error);
    } finally {
      if (mounted) {
        setState(() {
          _isLocationLoading = false;
        });
      }
      unawaited(_tryAutoCheckoutIfNeeded());
    }
  }

  Future<void> _resolveAddress(Position position) async {
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (places.isEmpty || !mounted) return;

      final place = places.first;
      final parts = <String>[
        if ((place.street ?? '').trim().isNotEmpty) (place.street ?? '').trim(),
        if ((place.subLocality ?? '').trim().isNotEmpty)
          (place.subLocality ?? '').trim(),
        if ((place.locality ?? '').trim().isNotEmpty)
          (place.locality ?? '').trim(),
        if ((place.administrativeArea ?? '').trim().isNotEmpty)
          (place.administrativeArea ?? '').trim(),
      ];

      if (parts.isEmpty) return;

      setState(() {
        _currentAddress = parts.join(', ');
      });
    } catch (_) {
      // Biarkan fallback lat/lng jika reverse geocoding gagal.
    }
  }

  // Menggeser kamera map ke posisi terbaru pengguna jika map sudah siap.
  Future<void> _focusMapToPosition(Position position) async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: 18,
            tilt: 0,
          ),
        ),
      );
    } catch (error) {
      log('skip_camera_update=$error');
    }
  }

  // Menghitung jarak pengguna (meter) ke titik check in yang ditentukan.
  double _distanceToCheckInTargetMeters(Position position) {
    return Geolocator.distanceBetween(
      position.latitude,
      position.longitude,
      _checkInTargetLat,
      _checkInTargetLng,
    );
  }

  bool _isAtOrAfterHour(int hour, {DateTime? now}) {
    final value = now ?? DateTime.now();
    return value.hour >= hour;
  }

  Future<void> _tryAutoCheckoutIfNeeded() async {
    if (!mounted || _isAutoCheckoutRunning || _isSubmitting) return;
    if (!_canCheckoutToday) return;
    if (!_isAtOrAfterHour(_autoCheckOutHour)) return;

    final fallbackAddress =
        'Auto checkout setelah 17:00 (tanpa validasi lokasi)';
    final checkOutLat = _currentPosition?.latitude ?? _checkInTargetLat;
    final checkOutLng = _currentPosition?.longitude ?? _checkInTargetLng;
    final checkOutAddress = _currentAddress == 'Lokasi belum tersedia'
        ? fallbackAddress
        : _currentAddress;

    _isAutoCheckoutRunning = true;
    try {
      final now = DateTime.now();
      final date = _dateFormat.format(now);
      await checkOutAttendance(
        attendanceDate: date,
        checkOut: _timeFormat.format(now),
        checkOutLat: checkOutLat,
        checkOutLng: checkOutLng,
        checkOutAddress: checkOutAddress,
        status: 'pulang',
      );

      if (!mounted) return;
      await _fetchTodayAttendance();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Auto check out dijalankan karena sudah melewati 17:00.',
          ),
        ),
      );
      HomeScreen.refresh();
    } catch (_) {
      // Auto checkout bersifat best effort; kegagalan tidak memblokir alur utama.
    } finally {
      _isAutoCheckoutRunning = false;
    }
  }

  // Memvalidasi kondisi presensi lalu mengirim request check in, check out, atau izin.
  Future<void> _submitAttendance() async {
    if (_isSubmitting) return;

    if (_isAttendanceCompletedToday) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Presensi hari ini sudah selesai.')),
      );
      return;
    }

    if (_selectedMode == AttendanceMode.izin &&
        _reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Alasan izin wajib diisi.')));
      return;
    }

    // Validasi radius untuk check in dan check out.
    final isCheckInFlow =
        !_canCheckoutToday && _selectedMode == AttendanceMode.hadir;
    final isCheckOutFlow = _canCheckoutToday;

    if (isCheckInFlow && !_isAtOrAfterHour(_checkInStartHour)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check in hanya bisa dimulai dari jam 05:00.'),
        ),
      );
      return;
    }

    if (isCheckOutFlow && !_isAtOrAfterHour(_checkOutStartHour)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check out hanya bisa dilakukan mulai jam 15:00.'),
        ),
      );
      return;
    }

    if (isCheckInFlow || isCheckOutFlow) {
      final position = _currentPosition;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lokasi belum siap. Silakan refresh lokasi.'),
          ),
        );
        return;
      }

      final distanceInMeters = _distanceToCheckInTargetMeters(position);
      if (distanceInMeters > _maxCheckInDistanceMeters) {
        final roundedDistance = distanceInMeters.toStringAsFixed(0);
        final actionLabel = isCheckOutFlow ? 'check out' : 'check in';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Anda berada $roundedDistance meter dari titik presensi. Maksimal jarak $actionLabel adalah ${_maxCheckInDistanceMeters.toStringAsFixed(0)} meter.',
            ),
          ),
        );
        return;
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final date = _dateFormat.format(now);

      late final AttendanceApiResponse response;
      if (_canCheckoutToday) {
        response = await checkOutAttendance(
          attendanceDate: date,
          checkOut: _timeFormat.format(now),
          checkOutLat: _currentPosition!.latitude,
          checkOutLng: _currentPosition!.longitude,
          checkOutAddress: _currentAddress,
          status: 'pulang',
        );
      } else if (_selectedMode == AttendanceMode.hadir) {
        response = await checkInAttendance(
          attendanceDate: date,
          checkIn: _timeFormat.format(now),
          checkInLat: _currentPosition!.latitude,
          checkInLng: _currentPosition!.longitude,
          checkInAddress: _currentAddress,
          status: 'masuk',
        );
      } else {
        response = await submitIzin(
          date: date,
          alasanIzin: _reasonController.text.trim(),
        );
      }

      if (!mounted) return;
      _reasonController.clear();
      await _fetchTodayAttendance();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));

      HomeScreen.refresh();
    } catch (error) {
      _showErrorMessage(error);
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // Menampilkan error dengan format pesan yang konsisten untuk semua proses async.
  void _showErrorMessage(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
    );
  }

  @override
  // Menyusun seluruh tampilan halaman presensi berdasarkan state saat ini.
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDarkMode = theme.brightness == Brightness.dark;
    final detailTileBackground = isDarkMode
        ? AppColor.fieldFillDark
        : AppColor.backgroundLight;
    final detailTileLabelColor = isDarkMode
        ? colorScheme.onSurface.withValues(alpha: 0.9)
        : colorScheme.onSurfaceVariant;
    final bottomBarBackground = isDarkMode
        ? colorScheme.surface
        : AppColor.backgroundLight;
    final selectedChipBackground = isDarkMode
        ? AppColor.primarySoft.withValues(alpha: 0.92)
        : AppColor.primary.withValues(alpha: 0.18);
    final selectedChipBorder = isDarkMode
        ? AppColor.primarySoft
        : AppColor.primary.withValues(alpha: 0.55);
    final selectedChipTextColor = isDarkMode
        ? AppColor.backgroundDark
        : AppColor.primary;
    final unselectedChipBackground = isDarkMode
        ? AppColor.fieldFillDark
        : theme.scaffoldBackgroundColor;
    final unselectedChipBorder = isDarkMode
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.35)
        : AppColor.border.withValues(alpha: 0.5);
    final unselectedChipTextColor = isDarkMode
        ? colorScheme.onSurface.withValues(alpha: 0.9)
        : colorScheme.onSurfaceVariant;

    final statusLabel = _isIzinToday
        ? 'Sudah izin hari ini'
        : ((_todayAttendance?.checkOutTime ?? '').trim().isNotEmpty)
        ? 'Sudah check out hari ini'
        : ((_todayAttendance?.checkInTime ?? '').trim().isNotEmpty)
        ? 'Sudah check in hari ini'
        : _hasTodayAttendance
        ? ((_todayAttendance?.status ?? '').toLowerCase() == 'izin')
              ? 'Sudah izin hari ini'
              : 'Sudah check in hari ini'
        : 'Belum check in';

    final statusColor = _isIzinToday
        ? AppColor.warning
        : (((_todayAttendance?.checkOutTime ?? '').trim().isNotEmpty) ||
              ((_todayAttendance?.checkInTime ?? '').trim().isNotEmpty))
        ? AppColor.success
        : AppColor.error;

    final currentLatLng = _currentPosition == null
        ? const LatLng(-6.200000, 106.816666)
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    final isMapSectionLoading = !_isMapReady || _isLocationLoading;
    final isBeforeCheckInTime = !_isAtOrAfterHour(_checkInStartHour);
    final isBeforeCheckOutTime = !_isAtOrAfterHour(_checkOutStartHour);
    final isCheckInFlow =
        !_canCheckoutToday && _selectedMode == AttendanceMode.hadir;
    final isActionBlockedByTime =
        (isCheckInFlow && isBeforeCheckInTime) ||
        (_canCheckoutToday && isBeforeCheckOutTime);
    final buttonLabel = _isAttendanceCompletedToday
        ? 'Presensi Hari Ini Selesai'
        : (isCheckInFlow && isBeforeCheckInTime)
        ? 'Check In Mulai 05:00'
        : (_canCheckoutToday && isBeforeCheckOutTime)
        ? 'Check Out Mulai 15:00'
        : _canCheckoutToday
        ? 'Check Out Sekarang'
        : _selectedMode == AttendanceMode.hadir
        ? 'Check In Sekarang'
        : 'Ajukan Izin';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: true,
        title: Text(
          'Presensi',
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadInitialData,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow:
                                Theme.of(context).brightness == Brightness.dark
                                ? const []
                                : [
                                    BoxShadow(
                                      color: statusColor.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.event_available_rounded,
                                      color: statusColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Status Presensi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      statusLabel,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: statusColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: detailTileBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Tanggal',
                                            style: TextStyle(
                                              color: detailTileLabelColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _todayAttendance?.attendanceDate ??
                                                _dateFormat.format(
                                                  DateTime.now(),
                                                ),
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: detailTileBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Check in',
                                            style: TextStyle(
                                              color: detailTileLabelColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _todayAttendance?.checkInTime ??
                                                '-',
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: detailTileBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Status',
                                            style: TextStyle(
                                              color: detailTileLabelColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            (_todayAttendance?.status ??
                                                    'belum absen')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      decoration: BoxDecoration(
                                        color: detailTileBackground,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Check out',
                                            style: TextStyle(
                                              color: detailTileLabelColor,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            _todayAttendance?.checkOutTime ??
                                                '-',
                                            style: TextStyle(
                                              color: colorScheme.onSurface,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow:
                                Theme.of(context).brightness == Brightness.dark
                                ? const []
                                : [
                                    BoxShadow(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: AppColor.primary.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.my_location,
                                      color: AppColor.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Lokasi Saat Ini',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _currentAddress,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 220,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    children: [
                                      GoogleMap(
                                        initialCameraPosition: CameraPosition(
                                          target: currentLatLng,
                                          zoom: 16,
                                        ),
                                        myLocationEnabled: true,
                                        myLocationButtonEnabled: true,
                                        zoomControlsEnabled: true,
                                        onMapCreated: (controller) {
                                          _mapController = controller;
                                          if (mounted && !_isMapReady) {
                                            setState(() {
                                              _isMapReady = true;
                                            });
                                          }
                                          final position = _currentPosition;
                                          if (position != null) {
                                            _focusMapToPosition(position);
                                          }
                                        },
                                        markers: {
                                          Marker(
                                            markerId: const MarkerId(
                                              'current_location',
                                            ),
                                            position: currentLatLng,
                                            infoWindow: const InfoWindow(
                                              title: 'Lokasi Anda',
                                            ),
                                          ),
                                        },
                                      ),
                                      if (isMapSectionLoading)
                                        Positioned.fill(
                                          child: ColoredBox(
                                            color: theme.colorScheme.surface
                                                .withValues(alpha: 0.45),
                                            child: const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    decoration: BoxDecoration(
                      color: bottomBarBackground,
                      boxShadow: isDarkMode
                          ? const []
                          : [
                              BoxShadow(
                                color: AppColor.primary.withValues(alpha: 0.06),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_canCheckoutToday &&
                            !_isAttendanceCompletedToday) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow:
                                  Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const []
                                  : [
                                      BoxShadow(
                                        color: AppColor.primary.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pilih Presensi',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  children: [
                                    ChoiceChip(
                                      selected:
                                          _selectedMode == AttendanceMode.hadir,
                                      showCheckmark: false,
                                      selectedColor: selectedChipBackground,
                                      backgroundColor: unselectedChipBackground,
                                      side: BorderSide(
                                        color:
                                            _selectedMode ==
                                                AttendanceMode.hadir
                                            ? selectedChipBorder
                                            : unselectedChipBorder,
                                        width:
                                            _selectedMode ==
                                                AttendanceMode.hadir
                                            ? 1.4
                                            : 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      label: Text(
                                        'Hadir',
                                        style: TextStyle(
                                          color:
                                              _selectedMode ==
                                                  AttendanceMode.hadir
                                              ? selectedChipTextColor
                                              : unselectedChipTextColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedMode = AttendanceMode.hadir;
                                        });
                                      },
                                    ),
                                    ChoiceChip(
                                      selected:
                                          _selectedMode == AttendanceMode.izin,
                                      showCheckmark: false,
                                      selectedColor: selectedChipBackground,
                                      backgroundColor: unselectedChipBackground,
                                      side: BorderSide(
                                        color:
                                            _selectedMode == AttendanceMode.izin
                                            ? selectedChipBorder
                                            : unselectedChipBorder,
                                        width:
                                            _selectedMode == AttendanceMode.izin
                                            ? 1.4
                                            : 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      label: Text(
                                        'Izin',
                                        style: TextStyle(
                                          color:
                                              _selectedMode ==
                                                  AttendanceMode.izin
                                              ? selectedChipTextColor
                                              : unselectedChipTextColor,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedMode = AttendanceMode.izin;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                                if (_selectedMode == AttendanceMode.izin) ...[
                                  const SizedBox(height: 8),
                                  CustomTextField(
                                    controller: _reasonController,
                                    hintText: 'Alasan Izin',
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed:
                                (_isSubmitting ||
                                    _isAttendanceCompletedToday ||
                                    isActionBlockedByTime)
                                ? null
                                : _submitAttendance,
                            icon: _isSubmitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColor.textOnPrimary,
                                    ),
                                  )
                                : Icon(
                                    _isAttendanceCompletedToday
                                        ? Icons.check_circle_rounded
                                        : _canCheckoutToday
                                        ? Icons.logout_rounded
                                        : _selectedMode == AttendanceMode.hadir
                                        ? Icons.fingerprint
                                        : Icons.event_note_rounded,
                                  ),
                            label: Text(buttonLabel),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: AppColor.textOnPrimary,
                              disabledBackgroundColor: AppColor.divider,
                              elevation: isDarkMode ? 0 : 6,
                              shadowColor: isDarkMode
                                  ? Colors.transparent
                                  : AppColor.primary.withValues(alpha: 0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

enum AttendanceMode { hadir, izin }
