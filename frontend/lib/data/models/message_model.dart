import 'package:json_annotation/json_annotation.dart';

part 'message_model.g.dart';

@JsonSerializable()
class MessageModel {
  final String id;
  final String chatId;
  final String role;
  final String content;
  final int? tokensInput;
  final int? tokensOutput;
  final String? model;
  final DateTime createdAt;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.role,
    required this.content,
    this.tokensInput,
    this.tokensOutput,
    this.model,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) =>
      _$MessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$MessageModelToJson(this);

  MessageModel copyWith({
    String? id,
    String? chatId,
    String? role,
    String? content,
    int? tokensInput,
    int? tokensOutput,
    String? model,
    DateTime? createdAt,
  }) {
    return MessageModel(
      id: id ?? this.id,
      chatId: chatId ?? this.chatId,
      role: role ?? this.role,
      content: content ?? this.content,
      tokensInput: tokensInput ?? this.tokensInput,
      tokensOutput: tokensOutput ?? this.tokensOutput,
      model: model ?? this.model,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
