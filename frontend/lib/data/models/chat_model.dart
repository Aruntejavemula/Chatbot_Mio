import 'package:json_annotation/json_annotation.dart';

part 'chat_model.g.dart';

@JsonSerializable()
class ChatModel {
  final String id;
  final String userId;
  final String title;
  final String model;
  final String provider;
  final int messageCount;
  final String lastPreview;
  final String storageType;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ChatModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.model,
    required this.provider,
    required this.messageCount,
    required this.lastPreview,
    required this.storageType,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) =>
      _$ChatModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatModelToJson(this);

  ChatModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? model,
    String? provider,
    int? messageCount,
    String? lastPreview,
    String? storageType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      model: model ?? this.model,
      provider: provider ?? this.provider,
      messageCount: messageCount ?? this.messageCount,
      lastPreview: lastPreview ?? this.lastPreview,
      storageType: storageType ?? this.storageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
