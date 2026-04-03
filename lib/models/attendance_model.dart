class AttendanceRecord {
  final int? id;
  final String? attendanceDate;
  final String? checkInTime;
  final String? checkOutTime;
  final double? checkInLat;
  final double? checkInLng;
  final double? checkOutLat;
  final double? checkOutLng;
  final String? checkInAddress;
  final String? checkOutAddress;
  final String? status;
  final String? alasanIzin;

  const AttendanceRecord({
    this.id,
    this.attendanceDate,
    this.checkInTime,
    this.checkOutTime,
    this.checkInLat,
    this.checkInLng,
    this.checkOutLat,
    this.checkOutLng,
    this.checkInAddress,
    this.checkOutAddress,
    this.status,
    this.alasanIzin,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceRecord(
      id: _toInt(json['id']),
      attendanceDate: json['attendance_date']?.toString(),
      checkInTime:
          json['check_in_time']?.toString() ?? _extractTime(json['check_in']),
      checkOutTime:
          json['check_out_time']?.toString() ?? _extractTime(json['check_out']),
      checkInLat: _toDouble(json['check_in_lat']),
      checkInLng: _toDouble(json['check_in_lng']),
      checkOutLat: _toDouble(json['check_out_lat']),
      checkOutLng: _toDouble(json['check_out_lng']),
      checkInAddress: json['check_in_address']?.toString(),
      checkOutAddress: json['check_out_address']?.toString(),
      status: json['status']?.toString(),
      alasanIzin: json['alasan_izin']?.toString(),
    );
  }

  static String? _extractTime(dynamic dateTimeValue) {
    if (dateTimeValue == null) return null;
    final value = dateTimeValue.toString();
    if (!value.contains(' ')) return value;

    final parts = value.split(' ');
    if (parts.length < 2) return value;
    return parts[1];
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}

class AttendanceApiResponse {
  final String message;
  final AttendanceRecord? data;

  const AttendanceApiResponse({required this.message, this.data});

  factory AttendanceApiResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceApiResponse(
      message: json['message']?.toString() ?? '',
      data: json['data'] is Map<String, dynamic>
          ? AttendanceRecord.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AttendanceStats {
  final int totalAbsen;
  final int totalMasuk;
  final int totalIzin;
  final bool sudahAbsenHariIni;

  const AttendanceStats({
    required this.totalAbsen,
    required this.totalMasuk,
    required this.totalIzin,
    required this.sudahAbsenHariIni,
  });

  factory AttendanceStats.fromJson(Map<String, dynamic> json) {
    return AttendanceStats(
      totalAbsen: _toInt(json['total_absen']) ?? 0,
      totalMasuk: _toInt(json['total_masuk']) ?? 0,
      totalIzin: _toInt(json['total_izin']) ?? 0,
      sudahAbsenHariIni: json['sudah_absen_hari_ini'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}

class AttendanceStatsResponse {
  final String message;
  final AttendanceStats data;

  const AttendanceStatsResponse({required this.message, required this.data});

  factory AttendanceStatsResponse.fromJson(Map<String, dynamic> json) {
    return AttendanceStatsResponse(
      message: json['message']?.toString() ?? '',
      data: AttendanceStats.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}
