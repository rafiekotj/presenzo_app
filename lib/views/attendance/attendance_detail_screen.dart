import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:presenzo_app/core/constant/app_color.dart';
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/services/api/attendance.dart';
import 'package:presenzo_app/views/home/home_screen.dart';

class AttendanceDetailScreen extends StatefulWidget {
  final AttendanceRecord record;

  const AttendanceDetailScreen({super.key, required this.record});

  @override
  State<AttendanceDetailScreen> createState() => _AttendanceDetailScreenState();
}

class _AttendanceDetailScreenState extends State<AttendanceDetailScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  LatLngBounds? _markerBounds;
  bool _isDeleting = false;

  @override
  /// Menjalankan inisialisasi data peta saat layar detail dibuka.
  void initState() {
    super.initState();
    _prepareMapData();
  }

  /// Menyiapkan marker check-in/check-out dan menghitung batas area kamera peta.
  void _prepareMapData() {
    _markers = {};

    if (widget.record.checkInLat != null && widget.record.checkInLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('check_in'),
          position: LatLng(
            widget.record.checkInLat!,
            widget.record.checkInLng!,
          ),
          infoWindow: InfoWindow(
            title: 'Check-in',
            snippet: widget.record.checkInTime ?? 'Tidak ada waktu',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        ),
      );
    }

    if (widget.record.checkOutLat != null &&
        widget.record.checkOutLng != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('check_out'),
          position: LatLng(
            widget.record.checkOutLat!,
            widget.record.checkOutLng!,
          ),
          infoWindow: InfoWindow(
            title: 'Check-out',
            snippet: widget.record.checkOutTime ?? 'Tidak ada waktu',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    if (_markers.isNotEmpty) {
      final lats = _markers.map((m) => m.position.latitude).toList();
      final lngs = _markers.map((m) => m.position.longitude).toList();
      var south = lats.reduce((a, b) => a < b ? a : b);
      var north = lats.reduce((a, b) => a > b ? a : b);
      var west = lngs.reduce((a, b) => a < b ? a : b);
      var east = lngs.reduce((a, b) => a > b ? a : b);

      const minSpan = 0.002;
      final latSpan = north - south;
      final lngSpan = east - west;

      if (latSpan < minSpan) {
        final centerLat = (north + south) / 2;
        south = centerLat - (minSpan / 2);
        north = centerLat + (minSpan / 2);
      }

      if (lngSpan < minSpan) {
        final centerLng = (east + west) / 2;
        west = centerLng - (minSpan / 2);
        east = centerLng + (minSpan / 2);
      }

      _markerBounds = LatLngBounds(
        southwest: LatLng(south, west),
        northeast: LatLng(north, east),
      );
    } else {
      _markerBounds = null;
    }
  }

  /// Menangani konfirmasi dan proses hapus data absensi, lalu memicu refresh data home.
  Future<void> _handleDeleteAttendance() async {
    if (_isDeleting || widget.record.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Absensi'),
        content: const Text(
          'Apakah Anda yakin ingin menghapus data absensi ini?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColor.error)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
    });

    try {
      await deleteAttendance(id: widget.record.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Absensi berhasil dihapus')));

      HomeScreen.refresh();

      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColor.error,
        ),
      );

      setState(() {
        _isDeleting = false;
      });
    }
  }

  @override
  /// Menyusun seluruh tampilan detail kehadiran berdasarkan data absensi yang dipilih.
  Widget build(BuildContext context) {
    final status = (widget.record.status ?? '').toLowerCase();
    final statusColor = switch (status) {
      'masuk' => AppColor.success,
      'izin' => AppColor.warning,
      'terlambat' => AppColor.secondary,
      _ => AppColor.error,
    };
    final statusLabel = switch (status) {
      'masuk' => 'Hadir',
      'izin' => 'Izin',
      'terlambat' => 'Terlambat',
      _ => 'Tidak Hadir',
    };

    final formattedDate = widget.record.attendanceDate != null
        ? DateFormat(
            'EEEE, d MMMM y',
            'id_ID',
          ).format(DateTime.parse(widget.record.attendanceDate!))
        : 'Tanggal tidak diketahui';

    return Scaffold(
      backgroundColor: AppColor.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppColor.backgroundLight,
        foregroundColor: AppColor.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 56,
        centerTitle: true,
        title: const Text(
          'Detail Kehadiran',
          style: TextStyle(
            color: AppColor.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_markers.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.primary.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Lokasi Presensi',
                        style: TextStyle(
                          color: AppColor.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 240,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: GoogleMap(
                            onMapCreated: (controller) {
                              _mapController = controller;
                              final bounds = _markerBounds;
                              if (bounds == null) return;
                              Future.delayed(
                                const Duration(milliseconds: 500),
                                () {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newLatLngBounds(bounds, 30),
                                  );
                                },
                              );
                            },
                            initialCameraPosition: CameraPosition(
                              target: LatLng(
                                widget.record.checkInLat ?? 0,
                                widget.record.checkInLng ?? 0,
                              ),
                              zoom: 16,
                            ),
                            myLocationEnabled: true,
                            myLocationButtonEnabled: true,
                            zoomControlsEnabled: true,
                            markers: _markers,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.10),
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
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: statusColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Status',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                  if ((widget.record.status ?? '').toLowerCase() == 'izin' &&
                      widget.record.alasanIzin != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Alasan: ${widget.record.alasanIzin}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColor.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tanggal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColor.success.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Check-in',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Waktu',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.record.checkInTime ?? '-',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Lokasi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColor.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.record.checkInAddress ?? '-',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColor.textPrimary,
                    ),
                  ),
                  if (widget.record.checkInLat != null &&
                      widget.record.checkInLng != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.success.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${widget.record.checkInLat?.toStringAsFixed(5)}, ${widget.record.checkInLng?.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColor.success,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (widget.record.checkOutTime != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColor.error.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Check-out',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Waktu',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.record.checkOutTime ?? '-',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Lokasi',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColor.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.record.checkOutAddress ?? '-',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColor.textPrimary,
                      ),
                    ),
                    if (widget.record.checkOutLat != null &&
                        widget.record.checkOutLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColor.error.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.record.checkOutLat?.toStringAsFixed(5)}, ${widget.record.checkOutLng?.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColor.error,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isDeleting ? null : _handleDeleteAttendance,
                icon: _isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColor.textOnPrimary,
                        ),
                      )
                    : const Icon(Icons.delete_outline),
                label: const Text('Hapus Absensi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.error,
                  foregroundColor: AppColor.textOnPrimary,
                  disabledBackgroundColor: AppColor.error.withValues(
                    alpha: 0.5,
                  ),
                  elevation: 6,
                  shadowColor: AppColor.error.withValues(alpha: 0.25),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
