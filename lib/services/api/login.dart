import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/login_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';

// Mengirim email dan password ke server untuk proses login user.
Future<LoginModel?> loginUser({
  required String email,
  required String password,
}) async {
  final response = await http.post(
    Uri.parse(Endpoint.login),
    headers: {"Accept": "application/json", "Content-Type": "application/json"},
    body: jsonEncode({"email": email, "password": password}),
  );

  log(response.body);
  if (response.statusCode == 200) {
    return LoginModel.fromJson(json.decode(response.body));
  }

  final error = LoginModel.fromJson(json.decode(response.body));
  log(error.toString());
  throw Exception(error.message);
}
