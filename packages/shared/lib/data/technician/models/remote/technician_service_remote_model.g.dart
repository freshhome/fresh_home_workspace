// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_service_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianServiceRemoteModel _$TechnicianServiceRemoteModelFromJson(
        Map<String, dynamic> json) =>
    TechnicianServiceRemoteModel(
      id: json['id'] as String,
      technicianId: json['technician_id'] as String,
      subServiceId: json['sub_service_id'] as String,
      capacityPerDay: (json['capacity_per_day'] as num).toInt(),
      isActive: json['is_active'] as bool? ?? true,
      subService: json['sub_services'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TechnicianServiceRemoteModelToJson(
        TechnicianServiceRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'technician_id': instance.technicianId,
      'sub_service_id': instance.subServiceId,
      'capacity_per_day': instance.capacityPerDay,
      'is_active': instance.isActive,
      'sub_services': instance.subService,
    };
