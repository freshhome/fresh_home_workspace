// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRemoteModel _$UserRemoteModelFromJson(Map<String, dynamic> json) =>
    UserRemoteModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String,
      lastName: json['last_name'] as String,
      email: json['email'] as String,
      accountStatus: $enumDecode(_$UserStatusEnumMap, json['account_status']),
      gender: json['gender'] as String,
      avatarUrl: json['avatar_url'] as String?,
      roles: (json['roles'] as List<dynamic>)
          .map((e) => $enumDecode(_$UserRoleEnumMap, e))
          .toList(),
      phones: (json['user_phones'] as List<dynamic>?)
          ?.map((e) => UserPhoneRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      addresses: (json['user_addresses'] as List<dynamic>?)
          ?.map(
              (e) => UserAddressRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$UserRemoteModelToJson(UserRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'email': instance.email,
      'account_status': _$UserStatusEnumMap[instance.accountStatus]!,
      'gender': instance.gender,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };

const _$UserStatusEnumMap = {
  UserStatus.active: 'active',
  UserStatus.pending: 'pending',
  UserStatus.suspended: 'suspended',
  UserStatus.banned: 'banned',
};

const _$UserRoleEnumMap = {
  UserRole.client: 'client',
  UserRole.technician: 'technician',
  UserRole.admin: 'admin',
};
