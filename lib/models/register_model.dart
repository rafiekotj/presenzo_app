// lib/day_30/models/register_model.dart

class RegisterModel {
  final String? message;
  final RegisterData? data;

  const RegisterModel({this.message, this.data});

  factory RegisterModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegisterModel();
    return RegisterModel(
      message: json['message'] as String?,
      data: RegisterData.fromJson(json['data'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {'message': message, 'data': data?.toJson()};
}

class RegisterData {
  final String? token;
  final RegisterUser? user;

  const RegisterData({this.token, this.user});

  factory RegisterData.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegisterData();
    return RegisterData(
      token: json['token'] as String?,
      user: RegisterUser.fromJson(json['user'] as Map<String, dynamic>?),
    );
  }

  Map<String, dynamic> toJson() => {'token': token, 'user': user?.toJson()};
}

class RegisterUser {
  final String? name;
  final String? email;
  final String? updatedAt;
  final String? createdAt;
  final int? id;

  const RegisterUser({
    this.name,
    this.email,
    this.updatedAt,
    this.createdAt,
    this.id,
  });

  factory RegisterUser.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const RegisterUser();
    return RegisterUser(
      name: json['name'] as String?,
      email: json['email'] as String?,
      updatedAt: json['updated_at'] as String?,
      createdAt: json['created_at'] as String?,
      id: (json['id'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'email': email,
    'updated_at': updatedAt,
    'created_at': createdAt,
    'id': id,
  };
}
