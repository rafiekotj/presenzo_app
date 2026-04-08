import 'package:presenzo_app/models/training_model.dart';

class BatchOptionItem {
  final int id;
  final String label;
  final List<TrainingOptionItem> trainings;

  const BatchOptionItem({
    required this.id,
    required this.label,
    this.trainings = const [],
  });
}

class BatchData {
  final int? id;
  final String? batchKe;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? updatedAt;

  BatchData({
    this.id,
    this.batchKe,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory BatchData.fromJson(Map<String, dynamic> json) => BatchData(
    id: _readInt(json, const ['id']),
    batchKe: _readString(json, const ['batch_ke']),
    startDate: _readString(json, const ['start_date']),
    endDate: _readString(json, const ['end_date']),
    createdAt: _readString(json, const ['created_at']),
    updatedAt: _readString(json, const ['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch_ke': batchKe,
    'start_date': startDate,
    'end_date': endDate,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static int? _readInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }
    return null;
  }
}
