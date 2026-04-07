import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/services/api/endpoint.dart';

// Mengirim permintaan OTP reset password ke email yang dimasukkan user.
Future<String> requestOtpForForgotPassword({required String email}) async {
  final response = await http.post(
    Uri.parse(Endpoint.forgotPassword),
    headers: {'Accept': 'application/json', 'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );

  log('forgot-password status=${response.statusCode} body=${response.body}');

  final dynamic decoded = json.decode(response.body);
  final message = decoded is Map<String, dynamic>
      ? decoded['message']?.toString()
      : null;

  if (response.statusCode == 200) {
    return message ?? 'OTP berhasil dikirim ke email';
  }

  throw Exception(message ?? 'Gagal mengirim OTP');
}
