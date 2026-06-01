import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/user/entities/user/address.dart';

part 'address_model.g.dart';

@HiveType(typeId: HiveTypeIds.address)
@JsonSerializable()
class AddressModel extends Address {
  @override
  @HiveField(0)
  final String governorate;

  @override
  @HiveField(1)
  final String city;

  @override
  @HiveField(2)
  final String street;

  @override
  @HiveField(3)
  @JsonKey(name: 'building_number')
  final String buildingNumber;

  @override
  @HiveField(4)
  @JsonKey(name: 'apartment')
  final String? apartmentNumber;

  @override
  @HiveField(5)
  @JsonKey(name: 'floor')
  final String? floorNumber;

  @override
  @HiveField(6)
  @JsonKey(includeIfNull: false)
  final String? id;

  @override
  @HiveField(7)
  final double? latitude;

  @override
  @HiveField(8)
  final double? longitude;

  AddressModel({
    this.id,
    required this.governorate,
    required this.city,
    required this.street,
    required this.buildingNumber,
    this.apartmentNumber,
    this.floorNumber,
    this.latitude,
    this.longitude,
  }) : super(
         id: id,
         governorate: governorate,
         city: city,
         street: street,
         buildingNumber: buildingNumber,
         apartmentNumber: apartmentNumber,
         floorNumber: floorNumber,
         latitude: latitude,
         longitude: longitude,
       );

  /// ✅ التحويل من JSON
  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  /// ✅ التحويل إلى JSON
  Map<String, dynamic> toJson() => _$AddressModelToJson(this);

  /// ✅ التحويل من Entity
  factory AddressModel.fromEntity(Address entity) {
    return AddressModel(
      id: entity.id,
      governorate: entity.governorate,
      city: entity.city,
      street: entity.street,
      buildingNumber: entity.buildingNumber,
      apartmentNumber: entity.apartmentNumber,
      floorNumber: entity.floorNumber,
      latitude: entity.latitude,
      longitude: entity.longitude,
    );
  }
}
