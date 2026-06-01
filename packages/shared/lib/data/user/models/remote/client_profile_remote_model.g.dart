// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_profile_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientProfileRemoteModel _$ClientProfileRemoteModelFromJson(
        Map<String, dynamic> json) =>
    ClientProfileRemoteModel(
      uid: json['id'] as String,
      addresses: (json['user_addresses'] as List<dynamic>?)
              ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      phoneNumbers: (json['user_phones'] as List<dynamic>?)
              ?.map((e) => PhoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$ClientProfileRemoteModelToJson(
        ClientProfileRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.uid,
      'user_addresses': instance.addresses.map((e) => e.toJson()).toList(),
      'user_phones': instance.phoneNumbers.map((e) => e.toJson()).toList(),
    };
