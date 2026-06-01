import 'package:json_annotation/json_annotation.dart';

part 'booking_snapshots.g.dart';

@JsonSerializable()
class ServiceSnapshotModel {
  final String id;
  final String subServiceId;
  final Map<String, String> name;
  final String image;

  const ServiceSnapshotModel({
    required this.id,
    required this.subServiceId,
    required this.name,
    required this.image,
  });

  factory ServiceSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceSnapshotModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceSnapshotModelToJson(this);
}

@JsonSerializable()
class AddressSnapshotModel {
  final String governorate;
  final String city;
  final String street;
  final String buildingNumber;
  final String? apartmentNumber;
  final String? floorNumber;
  final double? latitude;
  final double? longitude;

  const AddressSnapshotModel({
    required this.governorate,
    required this.city,
    required this.street,
    required this.buildingNumber,
    this.apartmentNumber,
    this.floorNumber,
    this.latitude,
    this.longitude,
  });

  factory AddressSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$AddressSnapshotModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressSnapshotModelToJson(this);
}

@JsonSerializable()
class PriceSnapshotModel {
  final double basePrice;
  final double extraFees;
  final double discount;
  final double total;
  final Map<String, dynamic>? metadata;

  const PriceSnapshotModel({
    required this.basePrice,
    required this.extraFees,
    required this.discount,
    required this.total,
    this.metadata,
  });

  factory PriceSnapshotModel.fromJson(Map<String, dynamic> json) =>
      _$PriceSnapshotModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceSnapshotModelToJson(this);
}
