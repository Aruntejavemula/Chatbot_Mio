// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionModel _$SubscriptionModelFromJson(Map<String, dynamic> json) =>
    SubscriptionModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      plan: json['plan'] as String,
      status: json['status'] as String,
      currentPeriodEnd: json['currentPeriodEnd'] == null
          ? null
          : DateTime.parse(json['currentPeriodEnd'] as String),
      countryBucket: json['countryBucket'] as String,
      stripeCustomerId: json['stripeCustomerId'] as String?,
      stripeSubscriptionId: json['stripeSubscriptionId'] as String?,
      razorpayCustomerId: json['razorpayCustomerId'] as String?,
      razorpaySubscriptionId: json['razorpaySubscriptionId'] as String?,
    );

Map<String, dynamic> _$SubscriptionModelToJson(SubscriptionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'plan': instance.plan,
      'status': instance.status,
      'currentPeriodEnd': instance.currentPeriodEnd?.toIso8601String(),
      'countryBucket': instance.countryBucket,
      'stripeCustomerId': instance.stripeCustomerId,
      'stripeSubscriptionId': instance.stripeSubscriptionId,
      'razorpayCustomerId': instance.razorpayCustomerId,
      'razorpaySubscriptionId': instance.razorpaySubscriptionId,
    };
