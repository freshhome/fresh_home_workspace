import 'package:json_annotation/json_annotation.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/data/user/models/remote/phone_model.dart';

part 'customer_profile_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CustomerProfileRemoteModel {
  @JsonKey(name: 'user_id')
  final String userId;
  @JsonKey(name: 'preferred_payment_method')
  final String preferredPaymentMethod;
  @JsonKey(name: 'user_addresses', defaultValue: [])
  final List<AddressModel> addresses;
  @JsonKey(name: 'user_phones', defaultValue: [])
  final List<PhoneModel> phoneNumbers;

  CustomerProfileRemoteModel({
    required this.userId,
    required this.preferredPaymentMethod,
    this.addresses = const [],
    this.phoneNumbers = const [],
  });

  factory CustomerProfileRemoteModel.fromJson(Map<String, dynamic> json) {
    final customerData = json['customer_profiles'] != null
        ? (json['customer_profiles'] is List
            ? (json['customer_profiles'] as List).firstOrNull as Map<String, dynamic>?
            : json['customer_profiles'] as Map<String, dynamic>?)
        : null;

    return CustomerProfileRemoteModel(
      userId: json['id'] as String? ?? customerData?['user_id'] as String? ?? '',
      preferredPaymentMethod: customerData?['preferred_payment_method'] as String? ?? 'cash',
      addresses: json['user_addresses'] != null
          ? (json['user_addresses'] as List)
              .map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
      phoneNumbers: json['user_phones'] != null
          ? (json['user_phones'] as List)
              .map((e) => PhoneModel.fromJson(e as Map<String, dynamic>))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() => _$CustomerProfileRemoteModelToJson(this);
}
