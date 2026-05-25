// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatModel _$ChatModelFromJson(Map<String, dynamic> json) => ChatModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  title: json['title'] as String,
  model: json['model'] as String,
  provider: json['provider'] as String,
  messageCount: (json['messageCount'] as num).toInt(),
  lastPreview: json['lastPreview'] as String,
  storageType: json['storageType'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$ChatModelToJson(ChatModel instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'title': instance.title,
  'model': instance.model,
  'provider': instance.provider,
  'messageCount': instance.messageCount,
  'lastPreview': instance.lastPreview,
  'storageType': instance.storageType,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};
