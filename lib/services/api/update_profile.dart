import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

// Memperbarui data profil user dengan hanya mengirim field yang terisi.
Future<GetUserModel?> updateProfile({
  required String name,
  String? phone,
  int? trainingId,
  int? batchId,
  String? jenisKelamin,
}) async {
  final token = await PreferenceHandler.getToken();

  final payload = <String, dynamic>{'name': name};
  if (phone != null && phone.trim().isNotEmpty) {
    payload['phone'] = phone.trim();
  }
  if (trainingId != null) {
    payload['training_id'] = trainingId;
  }
  if (batchId != null) {
    payload['batch_id'] = batchId;
  }
  if (jenisKelamin != null && jenisKelamin.trim().isNotEmpty) {
    payload['jenis_kelamin'] = jenisKelamin.trim();
  }

  final response = await http.put(
    Uri.parse(Endpoint.profile),
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}",
    },
    body: jsonEncode(payload),
  );

  log(response.body);
  if (response.statusCode == 200) {
    return GetUserModel.fromJson(json.decode(response.body));
  }

  final error = GetUserModel.fromJson(json.decode(response.body));
  log(error.toString());
  throw Exception(error.message ?? 'Gagal memperbarui profile');
}
