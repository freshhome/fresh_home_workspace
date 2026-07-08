// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'capacity_pool_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CapacityPoolRemoteModel _$CapacityPoolRemoteModelFromJson(
        Map<String, dynamic> json) =>
    CapacityPoolRemoteModel(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      title: json['title'] as String,
      mainServiceId: json['main_service_id'] as String,
      maxDailyCapacity: (json['max_daily_capacity'] as num).toInt(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$CapacityPoolRemoteModelToJson(
        CapacityPoolRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technician_id': instance.technicianId,
      'title': instance.title,
      'main_service_id': instance.mainServiceId,
      'max_daily_capacity': instance.maxDailyCapacity,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
