// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_usage_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TokenUsageModel _$TokenUsageModelFromJson(Map<String, dynamic> json) =>
    TokenUsageModel(
      dailyUsed: (json['dailyUsed'] as num).toInt(),
      dailyLimit: (json['dailyLimit'] as num).toInt(),
      monthlyUsed: (json['monthlyUsed'] as num).toInt(),
      monthlyLimit: (json['monthlyLimit'] as num).toInt(),
      currentModel: json['currentModel'] as String,
      resetTime: DateTime.parse(json['resetTime'] as String),
      canUseOurTokens: json['canUseOurTokens'] as bool,
    );

Map<String, dynamic> _$TokenUsageModelToJson(TokenUsageModel instance) =>
    <String, dynamic>{
      'dailyUsed': instance.dailyUsed,
      'dailyLimit': instance.dailyLimit,
      'monthlyUsed': instance.monthlyUsed,
      'monthlyLimit': instance.monthlyLimit,
      'currentModel': instance.currentModel,
      'resetTime': instance.resetTime.toIso8601String(),
      'canUseOurTokens': instance.canUseOurTokens,
    };
