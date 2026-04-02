import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

Future<GetUserModel?> updateProfile({required String name}) async {
  final token = await PreferenceHandler.getToken();
  final response = await http.put(
    Uri.parse(Endpoint.profile),
    headers: {
      "Accept": "application/json",
      "Content-Type": "application/json",
      "Authorization": "Bearer ${token ?? ''}",
    },
    body: jsonEncode({"name": name}),
  );

  log(response.body);
  if (response.statusCode == 200) {
    return GetUserModel.fromJson(json.decode(response.body));
  }

  final error = GetUserModel.fromJson(json.decode(response.body));
  log(error.toString());
  throw Exception(error.message ?? 'Gagal memperbarui profile');
}
