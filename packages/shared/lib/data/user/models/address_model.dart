import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/user/entities/user/address.dart';

part 'address_model.g.dart';

/// Data Model (DTO) for User Address in Fresh Home System V3.
/// V3 replaces street/building/floor/apartment/landmark with [addressDetails].
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
  final String addressDetails;
  @HiveField(6)
  final String? locationUrl;
  @HiveField(7)
  final double? latitude;
  @HiveField(8)
  final double? longitude;
  @HiveField(9)
  final bool isPrimary;
  @HiveField(10)
  final DateTime? deletedAt;
  @HiveField(11)
  final DateTime createdAt;
  @HiveField(12)
  final DateTime updatedAt;
  @HiveField(13)
  final int? governorateId;
  @HiveField(14)
  final int? cityId;
  @HiveField(15)
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
    required this.addressDetails,
    this.locationUrl,
    this.latitude,
    this.longitude,
    this.isPrimary = false,
    this.deletedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    // V3 → V2 legacy fallback: if address_details is absent, reconstruct from old fields.
    final rawAddressDetails = json['address_details'] as String?;
    final legacyStreet = json['street_or_compound'] as String? ?? json['street'] as String? ?? '';
    final legacyBuilding = json['building_identifier'] as String? ?? json['building_number'] as String? ?? '';
    final legacyFloor = json['floor'] as String?;
    final legacyApartment = json['apartment_or_unit'] as String? ?? json['apartment'] as String?;
    final legacyLandmark = json['landmark'] as String?;

    final addressDetails = rawAddressDetails?.isNotEmpty == true
        ? rawAddressDetails!
        : _reconstructAddressDetails(
            street: legacyStreet,
            building: legacyBuilding,
            floor: legacyFloor,
            apartment: legacyApartment,
            landmark: legacyLandmark,
          );

    return AddressModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      governorate: json['governorate'] as String? ?? '',
      city: json['city'] as String? ?? '',
      district: json['district'] as String? ?? '',
      governorateId: (json['governorate_id'] as num?)?.toInt(),
      cityId: (json['city_id'] as num?)?.toInt(),
      districtId: (json['district_id'] as num?)?.toInt(),
      addressDetails: addressDetails,
      locationUrl: json['location_url'] as String? ?? json['locationUrl'] as String?,
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
      'address_details': addressDetails,
      if (locationUrl != null && locationUrl!.isNotEmpty) 'location_url': locationUrl,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      'is_primary': isPrimary,
      if (deletedAt != null) 'deleted_at': deletedAt!.toIso8601String(),
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
      addressDetails: addressDetails,
      locationUrl: locationUrl,
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
      addressDetails: entity.addressDetails,
      locationUrl: entity.locationUrl,
      latitude: entity.latitude,
      longitude: entity.longitude,
      isPrimary: entity.isPrimary,
      deletedAt: entity.deletedAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Reconstructs a readable address_details string from legacy V2 fields
  /// to ensure backward compatibility when reading old DB records.
  static String _reconstructAddressDetails({
    required String street,
    required String building,
    String? floor,
    String? apartment,
    String? landmark,
  }) {
    final parts = <String>[];
    if (street.isNotEmpty) parts.add(street);
    if (building.isNotEmpty) parts.add(building);
    if (floor != null && floor.isNotEmpty) parts.add('الدور $floor');
    if (apartment != null && apartment.isNotEmpty) parts.add('شقة $apartment');
    if (landmark != null && landmark.isNotEmpty) parts.add('($landmark)');
    return parts.join('، ');
  }
}
