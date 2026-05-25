// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceModel _$DeviceModelFromJson(Map<String, dynamic> json) => DeviceModel(
  id: json['id'] as String,
  userId: json['userId'] as String,
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  deviceType: json['deviceType'] as String,
  lastSeen: DateTime.parse(json['lastSeen'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$DeviceModelToJson(DeviceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'lastSeen': instance.lastSeen.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
