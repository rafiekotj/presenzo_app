import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/register_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';

// Mengirim data pendaftaran akun baru beserta training, batch, dan jenis kelamin.
Future<RegisterModel?> registerUser({
  required String name,
  required String email,
  required String password,
  required int trainingId,
  required int batchId,
  required String jenisKelamin,
}) async {
  final response = await http.post(
    Uri.parse(Endpoint.register),
    headers: {"Accept": "application/json", "Content-Type": "application/json"},
    body: jsonEncode({
      "name": name,
      "email": email,
      "password": password,
      "training_id": trainingId,
      "batch_id": batchId,
      "jenis_kelamin": jenisKelamin,
    }),
  );

  log('register status=${response.statusCode} body=${response.body}');
  if (response.statusCode == 200) {
    return RegisterModel.fromJson(json.decode(response.body));
  } else {
    final dynamic decoded = json.decode(response.body);
    final error = RegisterModel.fromJson(decoded as Map<String, dynamic>?);

    String message = error.message ?? 'Pendaftaran gagal';
    if (decoded is Map<String, dynamic>) {
      final errors = decoded['errors'];
      if (errors is Map<String, dynamic> && errors.isNotEmpty) {
        final details = <String>[];
        errors.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            details.add('$key: ${value.first}');
          } else if (value != null) {
            details.add('$key: $value');
          }
        });
        if (details.isNotEmpty) {
          message = '$message\n${details.join('\n')}';
        }
      }
    }

    throw Exception(message);
  }
}
