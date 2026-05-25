// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MessageModel _$MessageModelFromJson(Map<String, dynamic> json) => MessageModel(
  id: json['id'] as String,
  chatId: json['chatId'] as String,
  role: json['role'] as String,
  content: json['content'] as String,
  tokensInput: (json['tokensInput'] as num?)?.toInt(),
  tokensOutput: (json['tokensOutput'] as num?)?.toInt(),
  model: json['model'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$MessageModelToJson(MessageModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'chatId': instance.chatId,
      'role': instance.role,
      'content': instance.content,
      'tokensInput': instance.tokensInput,
      'tokensOutput': instance.tokensOutput,
      'model': instance.model,
      'createdAt': instance.createdAt.toIso8601String(),
    };
