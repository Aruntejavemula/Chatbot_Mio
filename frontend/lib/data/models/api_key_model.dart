import 'package:json_annotation/json_annotation.dart';

part 'api_key_model.g.dart';

@JsonSerializable()
class ApiKeyModel {
  final String id;
  final String userId;
  final String provider;
  final String encryptedKey;
  final String iv;
  final DateTime createdAt;

  const ApiKeyModel({
    required this.id,
    required this.userId,
    required this.provider,
    required this.encryptedKey,
    required this.iv,
    required this.createdAt,
  });

  factory ApiKeyModel.fromJson(Map<String, dynamic> json) =>
      _$ApiKeyModelFromJson(json);

  Map<String, dynamic> toJson() => _$ApiKeyModelToJson(this);

  ApiKeyModel copyWith({
    String? id,
    String? userId,
    String? provider,
    String? encryptedKey,
    String? iv,
    DateTime? createdAt,
  }) {
    return ApiKeyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      provider: provider ?? this.provider,
      encryptedKey: encryptedKey ?? this.encryptedKey,
      iv: iv ?? this.iv,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
