import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/services/api/attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final TextEditingController _reasonController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm:ss');

  GoogleMapController? _mapController;
  Position? _currentPosition;
  String _currentAddress = 'Lokasi belum tersedia';

  AttendanceRecord? _todayAttendance;
  bool _sudahAbsenHariIni = false;

  bool _isLoading = true;
  bool _isRefreshingLocation = false;
  bool _isSubmitting = false;

  AttendanceMode _selectedMode = AttendanceMode.hadir;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    await Future.wait([_fetchCurrentLocation(), _loadAttendanceStatus()]);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadAttendanceStatus() async {
    final attendanceDate = _dateFormat.format(DateTime.now());
    AttendanceRecord? todayAttendance;
    bool sudahAbsen = false;

    try {
      final todayResponse = await getTodayAttendance(
        attendanceDate: attendanceDate,
      );
      todayAttendance = todayResponse.data;
    } catch (_) {
      todayAttendance = null;
    }

    try {
      final statsResponse = await getAttendanceStats();
      sudahAbsen = statsResponse.data.sudahAbsenHariIni;
    } catch (_) {
      sudahAbsen = false;
    }

    if (!mounted) return;
    setState(() {
      _todayAttendance = todayAttendance;
      _sudahAbsenHariIni = sudahAbsen || todayAttendance != null;
    });
  }

  Future<void> _fetchCurrentLocation() async {
    if (mounted) {
      setState(() {
        _isRefreshingLocation = true;
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
          accuracy: LocationAccuracy.high,
        ),
      );

      String address =
          'Lat ${position.latitude.toStringAsFixed(6)}, Lng ${position.longitude.toStringAsFixed(6)}';

      try {
        final places = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (places.isNotEmpty) {
          final place = places.first;
          final parts = <String>[
            if ((place.street ?? '').trim().isNotEmpty)
              (place.street ?? '').trim(),
            if ((place.subLocality ?? '').trim().isNotEmpty)
              (place.subLocality ?? '').trim(),
            if ((place.locality ?? '').trim().isNotEmpty)
              (place.locality ?? '').trim(),
            if ((place.administrativeArea ?? '').trim().isNotEmpty)
              (place.administrativeArea ?? '').trim(),
          ];

          if (parts.isNotEmpty) {
            address = parts.join(', ');
          }
        }
      } catch (_) {
        // Keep coordinate-based fallback address when reverse geocoding fails.
      }

      if (!mounted) return;
      setState(() {
        _currentPosition = position;
        _currentAddress = address;
      });

      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshingLocation = false;
        });
      }
    }
  }

  Future<void> _submitAttendance() async {
    if (_isSubmitting) return;

    if (_sudahAbsenHariIni) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda sudah melakukan presensi hari ini.'),
        ),
      );
      return;
    }

    if (_selectedMode == AttendanceMode.hadir && _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lokasi belum siap. Silakan refresh lokasi.'),
        ),
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

    setState(() {
      _isSubmitting = true;
    });

    try {
      final now = DateTime.now();
      final date = _dateFormat.format(now);

      late final AttendanceApiResponse response;
      if (_selectedMode == AttendanceMode.hadir) {
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
      await _loadAttendanceStatus();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(response.message)));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  String get _statusLabel {
    if (_sudahAbsenHariIni) {
      if ((_todayAttendance?.status ?? '').toLowerCase() == 'izin') {
        return 'Sudah izin hari ini';
      }
      return 'Sudah check in hari ini';
    }

    return 'Belum check in';
  }

  Color get _statusColor {
    if (_sudahAbsenHariIni) {
      if ((_todayAttendance?.status ?? '').toLowerCase() == 'izin') {
        return AppColor.warning;
      }
      return AppColor.success;
    }
    return AppColor.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColor.surface,
        elevation: 0,
        title: const Text(
          'Presensi',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _initializeData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildMapCard(),
                  const SizedBox(height: 12),
                  _buildLocationCard(),
                  const SizedBox(height: 12),
                  _buildStatusCard(),
                  const SizedBox(height: 12),
                  _buildModeCard(),
                  const SizedBox(height: 16),
                  _buildSubmitButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildMapCard() {
    final currentLatLng = _currentPosition == null
        ? const LatLng(-6.200000, 106.816666)
        : LatLng(_currentPosition!.latitude, _currentPosition!.longitude);

    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: AppColor.shadowLight,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GoogleMap(
        initialCameraPosition: CameraPosition(target: currentLatLng, zoom: 16),
        myLocationEnabled: true,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: false,
        onMapCreated: (controller) {
          _mapController = controller;
        },
        markers: {
          Marker(
            markerId: const MarkerId('current_location'),
            position: currentLatLng,
            infoWindow: const InfoWindow(title: 'Lokasi Anda'),
          ),
        },
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.my_location, color: AppColor.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Lokasi Saat Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColor.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _isRefreshingLocation ? null : _fetchCurrentLocation,
                icon: _isRefreshingLocation
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 16),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _currentAddress,
            style: const TextStyle(
              color: AppColor.textSecondary,
              fontSize: 12,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: _statusColor),
              const SizedBox(width: 8),
              Text(
                _statusLabel,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Tanggal: ${_todayAttendance?.attendanceDate ?? _dateFormat.format(DateTime.now())}',
            style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Check in: ${_todayAttendance?.checkInTime ?? '-'}',
            style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${(_todayAttendance?.status ?? 'belum absen').toUpperCase()}',
            style: const TextStyle(color: AppColor.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Presensi',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColor.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            children: [
              ChoiceChip(
                selected: _selectedMode == AttendanceMode.hadir,
                label: const Text('Hadir'),
                onSelected: (_) {
                  setState(() {
                    _selectedMode = AttendanceMode.hadir;
                  });
                },
              ),
              ChoiceChip(
                selected: _selectedMode == AttendanceMode.izin,
                label: const Text('Izin'),
                onSelected: (_) {
                  setState(() {
                    _selectedMode = AttendanceMode.izin;
                  });
                },
              ),
            ],
          ),
          if (_selectedMode == AttendanceMode.izin) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Alasan Izin',
                hintText: 'Contoh: Sakit dan perlu istirahat',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final buttonLabel = _selectedMode == AttendanceMode.hadir
        ? 'Check In Sekarang'
        : 'Ajukan Izin';

    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: (_isSubmitting || _sudahAbsenHariIni)
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
            : const Icon(Icons.fingerprint),
        label: Text(buttonLabel),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColor.primary,
          foregroundColor: AppColor.textOnPrimary,
          disabledBackgroundColor: AppColor.divider,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

enum AttendanceMode { hadir, izin }
