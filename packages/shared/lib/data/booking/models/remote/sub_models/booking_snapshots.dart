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

  factory ServiceSnapshotModel.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as String?;
    final nameMap = json['name'] != null 
        ? Map<String, String>.from(json['name'] as Map) 
        : {'ar': title ?? 'خدمة', 'en': title ?? 'Service'};
    return ServiceSnapshotModel(
      id: (json['id'] ?? json['subServiceId'] ?? '') as String,
      subServiceId: (json['subServiceId'] ?? json['id'] ?? '') as String,
      name: nameMap,
      image: (json['image'] ?? '') as String,
    );
  }

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

  factory AddressSnapshotModel.fromJson(Map<String, dynamic> json) {
    return AddressSnapshotModel(
      governorate: (json['governorate'] ?? '') as String,
      city: (json['city'] ?? '') as String,
      street: (json['street'] ?? '') as String,
      buildingNumber: (json['buildingNumber'] ?? json['building_number'] ?? '') as String,
      apartmentNumber: (json['apartmentNumber'] ?? json['apartment'] ?? json['apartment_number']) as String?,
      floorNumber: (json['floorNumber'] ?? json['floor'] ?? json['floor_number']) as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }

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

  factory PriceSnapshotModel.fromJson(Map<String, dynamic> json) {
    return PriceSnapshotModel(
      basePrice: (json['basePrice'] as num? ?? 0.0).toDouble(),
      extraFees: (json['extraFees'] as num? ?? 0.0).toDouble(),
      discount: (json['discount'] as num? ?? 0.0).toDouble(),
      total: (json['total'] as num? ?? 0.0).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => _$PriceSnapshotModelToJson(this);
}
