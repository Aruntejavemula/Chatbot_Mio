import 'package:json_annotation/json_annotation.dart';

part 'subscription_model.g.dart';

@JsonSerializable()
class SubscriptionModel {
  final String id;
  final String userId;
  final String plan;
  final String status;
  final DateTime? currentPeriodEnd;
  final String countryBucket;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final String? razorpayCustomerId;
  final String? razorpaySubscriptionId;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.status,
    this.currentPeriodEnd,
    required this.countryBucket,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.razorpayCustomerId,
    this.razorpaySubscriptionId,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionModelToJson(this);

  SubscriptionModel copyWith({
    String? id,
    String? userId,
    String? plan,
    String? status,
    DateTime? currentPeriodEnd,
    String? countryBucket,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    String? razorpayCustomerId,
    String? razorpaySubscriptionId,
  }) {
    return SubscriptionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      currentPeriodEnd: currentPeriodEnd ?? this.currentPeriodEnd,
      countryBucket: countryBucket ?? this.countryBucket,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      razorpayCustomerId: razorpayCustomerId ?? this.razorpayCustomerId,
      razorpaySubscriptionId:
          razorpaySubscriptionId ?? this.razorpaySubscriptionId,
    );
  }
}
