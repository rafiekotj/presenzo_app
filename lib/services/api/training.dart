import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

class TrainingOptionItem {
  final int id;
  final String label;

  const TrainingOptionItem({required this.id, required this.label});
}

// Mengambil daftar training dari server lalu mengubahnya ke format pilihan dropdown.
Future<List<TrainingOptionItem>> getTrainings() async {
  final token = await PreferenceHandler.getToken();
  final headers = <String, String>{"Accept": "application/json"};
  if ((token ?? '').isNotEmpty) {
    headers["Authorization"] = "Bearer ${token!}";
  }

  final response = await http.get(
    Uri.parse(Endpoint.trainings),
    headers: headers,
  );

  log(response.body);
  if (response.statusCode != 200) {
    throw Exception('Gagal mengambil data Training (${response.statusCode})');
  }

  final decoded = json.decode(response.body);
  if (decoded is! Map<String, dynamic>) {
    return const [];
  }

  final data = decoded['data'];
  final listData = data is List
      ? data
      : data is Map<String, dynamic>
      ? (data['items'] ?? data['records'] ?? data['data'])
      : null;

  if (listData is! List) {
    return const [];
  }

  return listData
      .whereType<Map<String, dynamic>>()
      .map((item) {
        final idValue = item['id'];
        final id = idValue is int ? idValue : int.tryParse('$idValue');
        if (id == null) {
          return null;
        }

        final label = _readLabel(item) ?? 'Training $id';
        return TrainingOptionItem(id: id, label: label);
      })
      .whereType<TrainingOptionItem>()
      .toList();
}

// Membaca nama training dari beberapa kemungkinan key respons API.
String? _readLabel(Map<String, dynamic> item) {
  const candidates = ['name', 'nama', 'title', 'training_name'];

  for (final key in candidates) {
    final value = item[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
