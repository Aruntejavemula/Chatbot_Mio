import 'package:json_annotation/json_annotation.dart';

part 'token_usage_model.g.dart';

@JsonSerializable()
class TokenUsageModel {
  final int dailyUsed;
  final int dailyLimit;
  final int monthlyUsed;
  final int monthlyLimit;
  final String currentModel;
  final DateTime resetTime;
  final bool canUseOurTokens;

  const TokenUsageModel({
    required this.dailyUsed,
    required this.dailyLimit,
    required this.monthlyUsed,
    required this.monthlyLimit,
    required this.currentModel,
    required this.resetTime,
    required this.canUseOurTokens,
  });

  factory TokenUsageModel.fromJson(Map<String, dynamic> json) =>
      _$TokenUsageModelFromJson(json);

  Map<String, dynamic> toJson() => _$TokenUsageModelToJson(this);

  TokenUsageModel copyWith({
    int? dailyUsed,
    int? dailyLimit,
    int? monthlyUsed,
    int? monthlyLimit,
    String? currentModel,
    DateTime? resetTime,
    bool? canUseOurTokens,
  }) {
    return TokenUsageModel(
      dailyUsed: dailyUsed ?? this.dailyUsed,
      dailyLimit: dailyLimit ?? this.dailyLimit,
      monthlyUsed: monthlyUsed ?? this.monthlyUsed,
      monthlyLimit: monthlyLimit ?? this.monthlyLimit,
      currentModel: currentModel ?? this.currentModel,
      resetTime: resetTime ?? this.resetTime,
      canUseOurTokens: canUseOurTokens ?? this.canUseOurTokens,
    );
  }
}
