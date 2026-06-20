// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_profile_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AdminProfileRemoteModel _$AdminProfileRemoteModelFromJson(
        Map<String, dynamic> json) =>
    AdminProfileRemoteModel(
      userId: json['user_id'] as String,
      adminPermissions: (json['admin_permissions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );

Map<String, dynamic> _$AdminProfileRemoteModelToJson(
        AdminProfileRemoteModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'admin_permissions': instance.adminPermissions,
    };
