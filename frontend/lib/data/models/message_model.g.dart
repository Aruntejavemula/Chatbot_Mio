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
  thinkingContent: json['thinking_content'] as String?,
  hasThinking: json['has_thinking'] as bool? ?? false,
  provider: json['provider'] as String?,
  cachedTokens: (json['cached_tokens'] as num?)?.toInt(),
  totalInputTokens: (json['total_input_tokens'] as num?)?.toInt(),
  outputTokens: (json['output_tokens'] as num?)?.toInt(),
  imageUrl: json['image_url'] as String?,
  imagePrompt: json['image_prompt'] as String?,
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
      'thinking_content': instance.thinkingContent,
      'has_thinking': instance.hasThinking,
      'provider': instance.provider,
      'cached_tokens': instance.cachedTokens,
      'total_input_tokens': instance.totalInputTokens,
      'output_tokens': instance.outputTokens,
      'image_url': instance.imageUrl,
      'image_prompt': instance.imagePrompt,
    };
