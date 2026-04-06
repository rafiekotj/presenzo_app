import 'package:presenzo_app/models/batch_model.dart';
import 'package:presenzo_app/models/training_model.dart';

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
  final int? trainingId;
  final int? batchId;
  final String? jenisKelamin;
  final String? emailVerifiedAt;
  final String? createdAt;
  final String? updatedAt;
  final BatchData? batch;
  final TrainingData? training;

  Data({
    this.id,
    this.name,
    this.email,
    this.phone,
    this.photoUrl,
    this.trainingId,
    this.batchId,
    this.jenisKelamin,
    this.emailVerifiedAt,
    this.createdAt,
    this.updatedAt,
    this.batch,
    this.training,
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
    trainingId: _readInt(json, const ['training_id', 'trainingId']),
    batchId: _readInt(json, const ['batch_id', 'batchId']),
    jenisKelamin: _readString(json, const ['jenis_kelamin']),
    emailVerifiedAt: json['email_verified_at'] as String?,
    createdAt: json['created_at'] as String?,
    updatedAt: json['updated_at'] as String?,
    batch: json['batch'] == null
        ? null
        : BatchData.fromJson(json['batch'] as Map<String, dynamic>),
    training: json['training'] == null
        ? null
        : TrainingData.fromJson(json['training'] as Map<String, dynamic>),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'profile_photo_url': photoUrl,
    'training_id': trainingId,
    'batch_id': batchId,
    'jenis_kelamin': jenisKelamin,
    'email_verified_at': emailVerifiedAt,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'batch': batch?.toJson(),
    'training': training?.toJson(),
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
