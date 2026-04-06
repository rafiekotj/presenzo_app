class GetUserModel {
  final String? message;
  final Data? data;

  GetUserModel({this.message, this.data});

  factory GetUserModel.fromJson(Map<String, dynamic> json) => GetUserModel(
    message: json['message'] as String?,
    data: json['data'] == null
        ? null
        : Data.fromJson(json['data'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {'message': message, 'data': data?.toJson()};
}

class Data {
  final int? id;
  final String? name;
  final String? email;
  final String? phone;
  final String? photoUrl;
  final String? batchKe;
  final String? trainingTitle;
  final int? trainingId;
  final int? batchId;
  final BatchInfo? batch;
  final TrainingInfo? training;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;

  Data({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.batchKe,
    this.trainingTitle,
    this.trainingId,
    this.batchId,
    this.batch,
    this.training,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
    id: json['id'] as int?,
    name: json['name'] as String?,
    email: json['email'] as String?,
    phone: _readString(json, const [
      'phone',
      'no_hp',
      'phone_number',
      'nomor_hp',
    ]),
    photoUrl: _readString(json, const [
      'profile_photo_url',
      'photo_url',
      'photo',
      'avatar',
    ]),
    batchKe: _readString(json, const ['batch_ke']),
    trainingTitle: _readString(json, const ['training_title']),
    trainingId: _readInt(json, const ['training_id', 'trainingId']),
    batchId: _readInt(json, const ['batch_id', 'batchId']),
    batch: _readObject(json, 'batch', BatchInfo.fromJson),
    training: _readObject(json, 'training', TrainingInfo.fromJson),
    emailVerifiedAt: json['email_verified_at'] as String?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profile_photo_url': photoUrl,
    'batch_ke': batchKe,
    'training_title': trainingTitle,
    'training_id': trainingId,
    'batch_id': batchId,
    'batch': batch?.toJson(),
    'training': training?.toJson(),
    'email_verified_at': emailVerifiedAt,
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

  static T? _readObject<T>(
    Map<String, dynamic> json,
    String key,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final value = json[key];
    if (value is Map<String, dynamic>) {
      return fromJson(value);
    }
    return null;
  }
}

class BatchInfo {
  final int? id;
  final String? batchKe;
  final String? startDate;
  final String? endDate;
  final String? createdAt;
  final String? updatedAt;

  const BatchInfo({
    this.id,
    this.batchKe,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  factory BatchInfo.fromJson(Map<String, dynamic> json) => BatchInfo(
    id: Data._readInt(json, const ['id']),
    batchKe: Data._readString(json, const ['batch_ke']),
    startDate: Data._readString(json, const ['start_date']),
    endDate: Data._readString(json, const ['end_date']),
    createdAt: Data._readString(json, const ['created_at']),
    updatedAt: Data._readString(json, const ['updated_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'batch_ke': batchKe,
    'start_date': startDate,
    'end_date': endDate,
    'created_at': createdAt,
    'updated_at': updatedAt,
  };
}

class TrainingInfo {
  final int? id;
  final String? title;
  final String? description;
  final int? participantCount;
  final String? standard;
  final String? duration;
  final String? createdAt;
  final String? updatedAt;

  const TrainingInfo({
    this.id,
    this.title,
    this.description,
    this.participantCount,
    this.standard,
    this.duration,
    this.createdAt,
    this.updatedAt,
  });

  factory TrainingInfo.fromJson(Map<String, dynamic> json) => TrainingInfo(
    id: Data._readInt(json, const ['id']),
    title: Data._readString(json, const ['title']),
    description: Data._readString(json, const ['description']),
    participantCount: Data._readInt(json, const ['participant_count']),
    standard: Data._readString(json, const ['standard']),
    duration: Data._readString(json, const ['duration']),
    createdAt: Data._readString(json, const ['created_at']),
    updatedAt: Data._readString(json, const ['updated_at']),
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
}
