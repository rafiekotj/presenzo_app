import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/services/api/endpoint.dart';

Future<String> resetPasswordWithOtp({
  required String email,
  required String otp,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse(Endpoint.resetPassword),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'otp': otp, 'password': password}),
  );

  log('reset-password status=${response.statusCode} body=${response.body}');

  final dynamic decoded = json.decode(response.body);
  final message = decoded is Map<String, dynamic>
      ? decoded['message']?.toString()
      : null;

  if (response.statusCode == 200) {
    return message ?? 'Password berhasil diperbarui';
  }

  throw Exception(message ?? 'Gagal memperbarui password');
}
