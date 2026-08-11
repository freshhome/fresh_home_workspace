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
    
    final resolvedId = (json['id'] ?? '') as String;
    final resolvedSubServiceId = (json['sub_service_id'] ?? 
                                  json['subServiceId'] ?? 
                                  json['service_id'] ?? 
                                  json['serviceId'] ?? 
                                  resolvedId) as String;

    return ServiceSnapshotModel(
      id: resolvedId,
      subServiceId: resolvedSubServiceId,
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
  final String street;
  final String buildingNumber;
  final String? apartmentNumber;
  final String? floorNumber;
  final String? landmark;
  final String? propertyType;
  final double? latitude;
  final double? longitude;

  const AddressSnapshotModel({
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
    required this.street,
    required this.buildingNumber,
    this.apartmentNumber,
    this.floorNumber,
    this.landmark,
    this.propertyType,
    this.latitude,
    this.longitude,
  });

  factory AddressSnapshotModel.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> data;
    if (json.containsKey('address') && json['address'] is Map) {
      data = Map<String, dynamic>.from(json['address'] as Map);
    } else {
      data = json;
    }

    final govAr = data['governorate_ar'] as String?;
    final govEn = data['governorate_en'] as String?;
    final cAr = data['city_ar'] as String?;
    final cEn = data['city_en'] as String?;
    final dAr = data['district_ar'] as String?;
    final dEn = data['district_en'] as String?;

    return AddressSnapshotModel(
      governorate: (data['governorate'] ?? govAr ?? govEn ?? '') as String,
      city: (data['city'] ?? cAr ?? cEn ?? '') as String,
      district: (data['district'] ?? dAr ?? dEn ?? '') as String,
      governorateId: (data['governorate_id'] as num?)?.toInt(),
      cityId: (data['city_id'] as num?)?.toInt(),
      districtId: (data['district_id'] as num?)?.toInt(),
      governorateAr: govAr,
      governorateEn: govEn,
      cityAr: cAr,
      cityEn: cEn,
      districtAr: dAr,
      districtEn: dEn,
      street: (data['street'] ?? data['street_or_compound'] ?? '') as String,
      buildingNumber: (data['buildingNumber'] ?? data['building_number'] ?? data['building_identifier'] ?? '') as String,
      apartmentNumber: (data['apartmentNumber'] ?? data['apartment'] ?? data['apartment_number'] ?? data['apartment_or_unit']) as String?,
      floorNumber: (data['floorNumber'] ?? data['floor'] ?? data['floor_number']) as String?,
      landmark: data['landmark'] as String?,
      propertyType: (data['propertyType'] ?? data['property_type']) as String?,
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshot_version': 2,
      'address': {
        'governorate': governorate,
        'city': city,
        'district': district,
        if (governorateId != null) 'governorate_id': governorateId,
        if (cityId != null) 'city_id': cityId,
        if (districtId != null) 'district_id': districtId,
        'governorate_ar': governorateAr ?? governorate,
        'governorate_en': governorateEn ?? governorate,
        'city_ar': cityAr ?? city,
        'city_en': cityEn ?? city,
        'district_ar': districtAr ?? district,
        'district_en': districtEn ?? district,
        'street_or_compound': street,
        'building_identifier': buildingNumber,
        if (apartmentNumber != null) 'apartment_or_unit': apartmentNumber,
        if (floorNumber != null) 'floor': floorNumber,
        if (landmark != null) 'landmark': landmark,
        if (propertyType != null) 'property_type': propertyType,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      },
    };
  }
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
