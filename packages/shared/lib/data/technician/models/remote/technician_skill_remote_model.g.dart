// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_skill_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianSkillRemoteModel _$TechnicianSkillRemoteModelFromJson(
        Map<String, dynamic> json) =>
    TechnicianSkillRemoteModel(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      subServiceId: json['sub_service_id'] as String,
      capacityPoolId: json['capacity_pool_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TechnicianSkillRemoteModelToJson(
        TechnicianSkillRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technician_id': instance.technicianId,
      'sub_service_id': instance.subServiceId,
      'capacity_pool_id': instance.capacityPoolId,
      'is_active': instance.isActive,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
