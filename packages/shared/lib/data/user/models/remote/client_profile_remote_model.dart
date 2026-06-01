import 'package:json_annotation/json_annotation.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/data/user/models/remote/phone_model.dart';

part 'client_profile_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class ClientProfileRemoteModel {
  @JsonKey(name: 'id')
  final String uid;
  @JsonKey(name: 'user_addresses', defaultValue: [])
  final List<AddressModel> addresses;
  @JsonKey(name: 'user_phones', defaultValue: [])
  final List<PhoneModel> phoneNumbers;

  ClientProfileRemoteModel({
    required this.uid,
    required this.addresses,
    required this.phoneNumbers,
  });

  factory ClientProfileRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$ClientProfileRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ClientProfileRemoteModelToJson(this);
}
