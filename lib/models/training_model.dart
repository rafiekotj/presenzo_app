class TrainingOptionItem {
  final int id;
  final String label;

  const TrainingOptionItem({required this.id, required this.label});
}

class TrainingData {
  final int? id;
  final String? title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final String? createdAt;
  final String? updatedAt;

  TrainingData({
    this.id,
    this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory TrainingData.fromJson(Map<String, dynamic> json) => TrainingData(
    id: _readInt(json, const ['id']),
    title: _readString(json, const ['title']),
    description: _readString(json, const ['description']),
    participantCount: _readInt(json, const ['participant_count']),
    standard: _readString(json, const ['standard']),
    duration: _readString(json, const ['duration']),
    createdAt: _readString(json, const ['created_at']),
    updatedAt: _readString(json, const ['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'participant_count': participantCount,
    'standard': standard,
    'duration': duration,
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
