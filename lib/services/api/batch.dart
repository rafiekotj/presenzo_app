import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;
import 'package:presenzo_app/services/api/endpoint.dart';
import 'package:presenzo_app/services/storage/preference.dart';

class BatchOptionItem {
  final int id;
  final String label;

  const BatchOptionItem({required this.id, required this.label});
}

// Mengambil daftar batch dari server lalu mengubahnya ke format pilihan dropdown.
Future<List<BatchOptionItem>> getBatches() async {
  final token = await PreferenceHandler.getToken();
  final headers = <String, String>{"Accept": "application/json"};
  if ((token ?? '').isNotEmpty) {
    headers["Authorization"] = "Bearer ${token!}";
  }

  final response = await http.get(
    Uri.parse(Endpoint.batches),
    headers: headers,
  );

  log(response.body);
  if (response.statusCode != 200) {
    throw Exception('Gagal mengambil data Batch (${response.statusCode})');
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

        final label = _readLabel(item) ?? 'Batch $id';
        return BatchOptionItem(id: id, label: label);
      })
      .whereType<BatchOptionItem>()
      .toList();
}

// Membaca nama batch dari beberapa kemungkinan key respons API.
String? _readLabel(Map<String, dynamic> item) {
  const candidates = ['name', 'nama', 'batch_name', 'batch_ke'];

  for (final key in candidates) {
    final value = item[key];
    if (value is String && value.trim().isNotEmpty) {
      return value;
    }
  }
  return null;
}
