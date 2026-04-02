import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/register_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';

Future<RegisterModel?> registerUser({
  required String name,
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse(Endpoint.register),
    headers: {"Accept": "application/json", "Content-Type": "application/json"},
    body: jsonEncode({"name": name, "email": email, "password": password}),
  );

  log(response.body);
  if (response.statusCode == 200) {
    return RegisterModel.fromJson(json.decode(response.body));
  } else {
    final error = RegisterModel.fromJson(json.decode(response.body));
    log(error.toString());

    throw Exception(error.message);
  }
}
