// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api_key_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ApiKeyModel _$ApiKeyModelFromJson(Map<String, dynamic> json) => ApiKeyModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  provider: json['provider'] as String,
  encryptedKey: json['encryptedKey'] as String,
  iv: json['iv'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$ApiKeyModelToJson(ApiKeyModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'provider': instance.provider,
      'encryptedKey': instance.encryptedKey,
      'iv': instance.iv,
      'createdAt': instance.createdAt.toIso8601String(),
    };
