// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shared_icon_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SharedIconRemoteModel _$SharedIconRemoteModelFromJson(
        Map<String, dynamic> json) =>
    SharedIconRemoteModel(
      id: json['id'] as String,
      name: Map<String, String>.from(json['name'] as Map),
      storagePath: json['storage_path'] as String,
      publicUrl: json['public_url'] as String,
      category: json['category'] as String,
      usageCount: (json['usage_count'] as num).toInt(),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SharedIconRemoteModelToJson(
        SharedIconRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'storage_path': instance.storagePath,
      'public_url': instance.publicUrl,
      'category': instance.category,
      'usage_count': instance.usageCount,
      'created_at': instance.createdAt?.toIso8601String(),
    };
