// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_profile_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TechnicianProfileRemoteModel _$TechnicianProfileRemoteModelFromJson(
        Map<String, dynamic> json) =>
    TechnicianProfileRemoteModel(
      userId: json['user_id'] as String,
      mainServiceId: json['main_service_id'] as String?,
      bio: json['bio'] as String?,
      rating: (json['rating'] as num?)?.toDouble() ?? 5.0,
      completedJobs: (json['completed_jobs'] as num?)?.toInt() ?? 0,
      isVerified: json['is_verified'] as bool? ?? false,
      isAvailable: json['is_available'] as bool? ?? false,
      serviceArea: json['service_area'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$TechnicianProfileRemoteModelToJson(
        TechnicianProfileRemoteModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'main_service_id': instance.mainServiceId,
      'bio': instance.bio,
      'rating': instance.rating,
      'completed_jobs': instance.completedJobs,
      'is_verified': instance.isVerified,
      'is_available': instance.isAvailable,
      'service_area': instance.serviceArea,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
