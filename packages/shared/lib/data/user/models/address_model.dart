import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/user/entities/user/address.dart';

part 'address_model.g.dart';

/// Data Model (DTO) for User Address in Fresh Home System V2.
@HiveType(typeId: HiveTypeIds.address)
class AddressModel {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String userId;
  @HiveField(2)
  final String governorate;
  @HiveField(3)
  final String city;
  @HiveField(4)
  final String district;
  @HiveField(5)
  final String streetOrCompound;
  @HiveField(6)
  final String buildingIdentifier;
  @HiveField(7)
  final String? floor;
  @HiveField(8)
  final String? apartmentOrUnit;
  @HiveField(9)
  final String? landmark;
  @HiveField(10)
  final double? latitude;
  @HiveField(11)
  final double? longitude;
  @HiveField(12)
  final bool isPrimary;
  @HiveField(13)
  final DateTime? deletedAt;
  @HiveField(14)
  final DateTime createdAt;
  @HiveField(15)
  final DateTime updatedAt;
  @HiveField(16)
  final String? propertyType;
  @HiveField(17)
  final int? governorateId;
  @HiveField(18)
  final int? cityId;
  @HiveField(19)
  final int? districtId;

  const AddressModel({
    required this.id,
    required this.userId,
    required this.governorate,
    required this.city,
    required this.district,
    this.governorateId,
    this.cityId,
    this.districtId,
    required this.streetOrCompound,
    required this.buildingIdentifier,
    this.floor,
    this.apartmentOrUnit,
    this.landmark,
    this.propertyType,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      governorateId: (json['governorate_id'] as num?)?.toInt(),
      cityId: (json['city_id'] as num?)?.toInt(),
      districtId: (json['district_id'] as num?)?.toInt(),
      streetOrCompound: json['street_or_compound'] as String? ?? json['street'] as String? ?? '',
      buildingIdentifier: json['building_identifier'] as String? ?? json['building_number'] as String? ?? '',
      floor: json['floor'] as String?,
      apartmentOrUnit: json['apartment_or_unit'] as String? ?? json['apartment'] as String?,
      landmark: json['landmark'] as String?,
      propertyType: json['property_type'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isPrimary: json['is_primary'] as bool? ?? false,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at'] as String) : null,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'governorate': governorate,
      'city': city,
      'district': district,
      if (governorateId != null) 'governorate_id': governorateId,
      if (cityId != null) 'city_id': cityId,
      if (districtId != null) 'district_id': districtId,
      'street_or_compound': streetOrCompound,
      'building_identifier': buildingIdentifier,
      'floor': floor,
      'apartment_or_unit': apartmentOrUnit,
      'landmark': landmark,
      'property_type': propertyType,
      'latitude': latitude,
      'longitude': longitude,
      'is_primary': isPrimary,
      'deleted_at': deletedAt?.toIso8601String(),
    };
  }

  Address toEntity() {
    return Address(
      id: id,
      userId: userId,
      governorate: governorate,
      city: city,
      district: district,
      governorateId: governorateId,
      cityId: cityId,
      districtId: districtId,
      streetOrCompound: streetOrCompound,
      buildingIdentifier: buildingIdentifier,
      floor: floor,
      apartmentOrUnit: apartmentOrUnit,
      landmark: landmark,
      propertyType: propertyType,
      latitude: latitude,
      longitude: longitude,
      isPrimary: isPrimary,
      deletedAt: deletedAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory AddressModel.fromEntity(Address entity) {
    return AddressModel(
      id: entity.id,
      userId: entity.userId,
      governorate: entity.governorate,
      city: entity.city,
      district: entity.district,
      governorateId: entity.governorateId,
      cityId: entity.cityId,
      districtId: entity.districtId,
      streetOrCompound: entity.streetOrCompound,
      buildingIdentifier: entity.buildingIdentifier,
      floor: entity.floor,
      apartmentOrUnit: entity.apartmentOrUnit,
      landmark: entity.landmark,
      propertyType: entity.propertyType,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isPrimary: entity.isPrimary,
      deletedAt: entity.deletedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
}
