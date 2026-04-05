import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/models/get_model.dart';
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

class ProfileOptionItem {
  final int id;
  final String label;

  const ProfileOptionItem({required this.id, required this.label});
}

Future<GetUserModel?> updateProfile({
  required String name,
  String? phone,
  int? trainingId,
  int? batchId,
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
    body: jsonEncode({"photo": base64Image}),
  );

  log(response.body);
  if (response.statusCode == 200) {
    return GetUserModel.fromJson(json.decode(response.body));
  }

  final error = GetUserModel.fromJson(json.decode(response.body));
  throw Exception(error.message ?? 'Gagal memperbarui foto profile');
}

Future<List<ProfileOptionItem>> getTrainings() async {
  return _getOptions(endpoint: Endpoint.trainings, fallbackPrefix: 'Training');
}

Future<List<ProfileOptionItem>> getBatches() async {
  return _getOptions(endpoint: Endpoint.batches, fallbackPrefix: 'Batch');
}

Future<List<ProfileOptionItem>> _getOptions({
  required String endpoint,
  required String fallbackPrefix,
}) async {
  final token = await PreferenceHandler.getToken();
  final headers = <String, String>{"Accept": "application/json"};
  if ((token ?? '').isNotEmpty) {
    headers["Authorization"] = "Bearer ${token!}";
  }

  final response = await http.get(Uri.parse(endpoint), headers: headers);

  log(response.body);
  if (response.statusCode != 200) {
    throw Exception('Gagal mengambil data $fallbackPrefix');
  }

  final decoded = json.decode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return const [];
  }

  final data = decoded['data'];
  if (data is! List) {
    return const [];
  }

  return data
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final idValue = item['id'];
        final id = idValue is int ? idValue : int.tryParse('$idValue');
        if (id == null) {
          return null;
        }

        final label = _readLabel(item) ?? '$fallbackPrefix $id';
        return ProfileOptionItem(id: id, label: label);
      })
      .whereType<ProfileOptionItem>()
      .toList();
}

String? _readLabel(Map<String, dynamic> item) {
  const candidates = [
    'name',
    'nama',
    'title',
    'batch_name',
    'training_name',
    'code',
  ];

  for (final key in candidates) {
    final value = item[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
