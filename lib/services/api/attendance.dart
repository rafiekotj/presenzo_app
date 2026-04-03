import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/attendance_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

Future<AttendanceApiResponse> checkInAttendance({
  required String attendanceDate,
  required String checkIn,
  required double checkInLat,
  required double checkInLng,
  required String checkInAddress,
  required String status,
  String? alasanIzin,
}) async {
  final token = await PreferenceHandler.getToken();
  final response = await http.post(
    Uri.parse(Endpoint.absenCheckIn),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    },
    body: jsonEncode({
      'attendance_date': attendanceDate,
      'check_in': checkIn,
      'check_in_lat': checkInLat,
      'check_in_lng': checkInLng,
      'check_in_address': checkInAddress,
      'status': status,
      if (alasanIzin != null && alasanIzin.isNotEmpty)
        'alasan_izin': alasanIzin,
    }),
  );

  log(response.body);
  final parsed = AttendanceApiResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );

  if (response.statusCode == 200) {
    return parsed;
  }

  throw Exception(parsed.message.isEmpty ? 'Gagal check in' : parsed.message);
}

Future<AttendanceApiResponse> submitIzin({
  required String date,
  required String alasanIzin,
}) async {
  final token = await PreferenceHandler.getToken();
  final response = await http.post(
    Uri.parse(Endpoint.izin),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    },
    body: jsonEncode({'date': date, 'alasan_izin': alasanIzin}),
  );

  log(response.body);
  final parsed = AttendanceApiResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );

  if (response.statusCode == 200) {
    return parsed;
  }

  throw Exception(
    parsed.message.isEmpty ? 'Gagal mengajukan izin' : parsed.message,
  );
}

Future<AttendanceApiResponse> getTodayAttendance({
  required String attendanceDate,
}) async {
  final token = await PreferenceHandler.getToken();
  final uri = Uri.parse(
    Endpoint.absenToday,
  ).replace(queryParameters: {'attendance_date': attendanceDate});

  final response = await http.get(
    uri,
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    },
  );

  log(response.body);
  final parsed = AttendanceApiResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );

  if (response.statusCode == 200 || response.statusCode == 404) {
    return parsed;
  }

  throw Exception(
    parsed.message.isEmpty
        ? 'Gagal mengambil absensi hari ini'
        : parsed.message,
  );
}

Future<AttendanceStatsResponse> getAttendanceStats() async {
  final token = await PreferenceHandler.getToken();

  final response = await http.get(
    Uri.parse(Endpoint.absenStats),
    headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer ${token ?? ''}',
    },
  );

  log(response.body);
  if (response.statusCode == 200) {
    return AttendanceStatsResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  final parsed = AttendanceApiResponse.fromJson(
    jsonDecode(response.body) as Map<String, dynamic>,
  );
  throw Exception(
    parsed.message.isEmpty
        ? 'Gagal mengambil statistik absensi'
        : parsed.message,
  );
}
