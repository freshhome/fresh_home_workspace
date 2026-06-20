// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_profile_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerProfileRemoteModel _$CustomerProfileRemoteModelFromJson(
        Map<String, dynamic> json) =>
    CustomerProfileRemoteModel(
      userId: json['user_id'] as String,
      preferredPaymentMethod: json['preferred_payment_method'] as String,
      addresses: (json['user_addresses'] as List<dynamic>?)
              ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      phoneNumbers: (json['user_phones'] as List<dynamic>?)
              ?.map((e) => PhoneModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

Map<String, dynamic> _$CustomerProfileRemoteModelToJson(
        CustomerProfileRemoteModel instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'preferred_payment_method': instance.preferredPaymentMethod,
      'user_addresses': instance.addresses.map((e) => e.toJson()).toList(),
      'user_phones': instance.phoneNumbers.map((e) => e.toJson()).toList(),
    };
