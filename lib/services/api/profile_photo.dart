import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

// Mengunggah foto profil baru dalam format base64 ke endpoint profil.
Future<GetUserModel?> updateProfilePhotoBase64({
  required String base64Image,
}) async {
  final token = await PreferenceHandler.getToken();
  final response = await http.put(
    Uri.parse(Endpoint.profilePhoto),
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}",
    },
    body: jsonEncode({"profile_photo": base64Image}),
  );

  log(response.body);
  if (response.statusCode == 200) {
    return GetUserModel.fromJson(json.decode(response.body));
  }

  final error = GetUserModel.fromJson(json.decode(response.body));
  throw Exception(error.message ?? 'Gagal memperbarui foto profile');
}
