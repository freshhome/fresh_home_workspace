import 'package:equatable/equatable.dart';
import 'package:shared/domain/user/value_objects/city_value.dart';
import 'package:shared/domain/user/value_objects/district_value.dart';
import 'package:shared/domain/user/value_objects/governorate_value.dart';

/// Domain Entity representing a User Address in Fresh Home System V2.
class Address extends Equatable {
  final String id;
  final String userId;
  final String governorate;
  final String city;
  final String district;
  final int? governorateId;
  final int? cityId;
  final int? districtId;
  final String? governorateAr;
  final String? governorateEn;
  final String? cityAr;
  final String? cityEn;
  final String? districtAr;
  final String? districtEn;
  final String streetOrCompound;
  final String buildingIdentifier;
  final String? floor;
  final String? apartmentOrUnit;
  final String? landmark;
  final String? propertyType;
  final double? latitude;
  final double? longitude;
  final bool isPrimary;
  final DateTime? deletedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Address({
    required this.id,
    required this.userId,
    required this.governorate,
    required this.city,
    required this.district,
    this.governorateId,
    this.cityId,
    this.districtId,
    this.governorateAr,
    this.governorateEn,
    this.cityAr,
    this.cityEn,
    this.districtAr,
    this.districtEn,
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

  bool get hasCoordinates => latitude != null && longitude != null;
  bool get isDeleted => deletedAt != null;

  /// Returns governorate name based on requested locale ('ar' or 'en').
  String getGovernorateName(String locale) {
    if (locale == 'en') return governorateEn ?? governorate;
    return governorateAr ?? governorate;
  }

  /// Returns city name based on requested locale ('ar' or 'en').
  String getCityName(String locale) {
    if (locale == 'en') return cityEn ?? city;
    return cityAr ?? city;
  }

  /// Returns district name based on requested locale ('ar' or 'en').
  String getDistrictName(String locale) {
    if (locale == 'en') return districtEn ?? district;
    return districtAr ?? district;
  }

  // Domain Value Object Accessors
  GovernorateValue get governorateValue => GovernorateValue(name: governorate, id: governorateId);
  CityValue get cityValue => CityValue(name: city, id: cityId, governorateId: governorateId);
  DistrictValue get districtValue => DistrictValue(name: district, id: districtId, cityId: cityId);

  /// PII Masking Contract: Masks sensitive fields for logging security.
  String maskedToString() {
    return 'Address(id: $id, userId: $userId, governorate: $governorate, city: $city, '
        'district: $district, governorateId: $governorateId, cityId: $cityId, districtId: $districtId, '
        'streetOrCompound: $streetOrCompound, buildingIdentifier: $buildingIdentifier, '
        'floor: ***, apartmentOrUnit: ***, landmark: ***, propertyType: $propertyType, latitude: ***, longitude: ***, '
        'isPrimary: $isPrimary, isDeleted: $isDeleted)';
  }

  Address copyWith({
    String? id,
    String? userId,
    String? governorate,
    String? city,
    String? district,
    int? governorateId,
    int? cityId,
    int? districtId,
    String? governorateAr,
    String? governorateEn,
    String? cityAr,
    String? cityEn,
    String? districtAr,
    String? districtEn,
    String? streetOrCompound,
    String? buildingIdentifier,
    String? floor,
    String? apartmentOrUnit,
    String? landmark,
    String? propertyType,
    double? latitude,
    double? longitude,
    bool? isPrimary,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Address(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      governorate: governorate ?? this.governorate,
      city: city ?? this.city,
      district: district ?? this.district,
      governorateId: governorateId ?? this.governorateId,
      cityId: cityId ?? this.cityId,
      districtId: districtId ?? this.districtId,
      governorateAr: governorateAr ?? this.governorateAr,
      governorateEn: governorateEn ?? this.governorateEn,
      cityAr: cityAr ?? this.cityAr,
      cityEn: cityEn ?? this.cityEn,
      districtAr: districtAr ?? this.districtAr,
      districtEn: districtEn ?? this.districtEn,
      streetOrCompound: streetOrCompound ?? this.streetOrCompound,
      buildingIdentifier: buildingIdentifier ?? this.buildingIdentifier,
      floor: floor ?? this.floor,
      apartmentOrUnit: apartmentOrUnit ?? this.apartmentOrUnit,
      landmark: landmark ?? this.landmark,
      propertyType: propertyType ?? this.propertyType,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isPrimary: isPrimary ?? this.isPrimary,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        governorate,
        city,
        district,
        governorateId,
        cityId,
        districtId,
        governorateAr,
        governorateEn,
        cityAr,
        cityEn,
        districtAr,
        districtEn,
        streetOrCompound,
        buildingIdentifier,
        floor,
        apartmentOrUnit,
        landmark,
        propertyType,
        latitude,
        longitude,
        isPrimary,
        deletedAt,
        createdAt,
        updatedAt,
      ];
}

