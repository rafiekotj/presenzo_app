import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

// Mengambil data profil user yang sedang login menggunakan token autentikasi.
Future<GetUserModel?> getUser() async {
  final token = await PreferenceHandler.getToken();
  final response = await http.get(
    Uri.parse(Endpoint.profile),
    headers: {
      "Accept": "application/json",
      "Authorization": "Bearer ${token ?? ''}",
    },
  );

  log(response.body);
  if (response.statusCode == 200) {
    return GetUserModel.fromJson(json.decode(response.body));
  } else {
    final error = GetUserModel.fromJson(json.decode(response.body));
    log(error.toString());

    throw Exception(error.message);
  }
}
