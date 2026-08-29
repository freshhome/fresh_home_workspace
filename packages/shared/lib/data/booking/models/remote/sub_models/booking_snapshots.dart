import 'dart:convert';

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

  factory ServiceSnapshotModel.fromJson(dynamic rawJson) {
    if (rawJson == null) {
      return const ServiceSnapshotModel(id: '', subServiceId: '', name: {}, image: '');
    }

    Map<String, dynamic> json;
    if (rawJson is String) {
      try {
        json = jsonDecode(rawJson) as Map<String, dynamic>;
      } catch (_) {
        return const ServiceSnapshotModel(id: '', subServiceId: '', name: {}, image: '');
      }
    } else if (rawJson is Map) {
      json = Map<String, dynamic>.from(rawJson);
    } else {
      return const ServiceSnapshotModel(id: '', subServiceId: '', name: {}, image: '');
    }

    final title = json['title'] as String?;
    final nameMap = json['name'] != null 
        ? (json['name'] is Map ? Map<String, String>.from(json['name'] as Map) : {'ar': json['name'].toString(), 'en': json['name'].toString()})
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'subServiceId': subServiceId,
    'sub_service_id': subServiceId,
    'name': name,
    'image': image,
  };
}

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

  factory AddressSnapshotModel.fromJson(dynamic rawJson) {
    if (rawJson == null) {
      return const AddressSnapshotModel(governorate: '', city: '', district: '', street: '', buildingNumber: '');
    }

    Map<String, dynamic> data;
    if (rawJson is String) {
      try {
        data = jsonDecode(rawJson) as Map<String, dynamic>;
      } catch (_) {
        return const AddressSnapshotModel(governorate: '', city: '', district: '', street: '', buildingNumber: '');
      }
    } else if (rawJson is Map) {
      data = Map<String, dynamic>.from(rawJson);
    } else {
      return const AddressSnapshotModel(governorate: '', city: '', district: '', street: '', buildingNumber: '');
    }

    if (data.containsKey('address') && data['address'] is Map) {
      data = Map<String, dynamic>.from(data['address'] as Map);
    }

    int? parseInt(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val);
      return null;
    }

    double? parseDouble(dynamic val) {
      if (val == null) return null;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val);
      return null;
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
      governorateId: parseInt(data['governorate_id'] ?? data['governorateId']),
      cityId: parseInt(data['city_id'] ?? data['cityId']),
      districtId: parseInt(data['district_id'] ?? data['districtId']),
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
      latitude: parseDouble(data['latitude']),
      longitude: parseDouble(data['longitude']),
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

  factory PriceSnapshotModel.fromJson(dynamic rawJson) {
    if (rawJson == null) {
      return const PriceSnapshotModel(
        basePrice: 0.0,
        extraFees: 0.0,
        discount: 0.0,
        total: 0.0,
      );
    }

    Map<String, dynamic> json;
    if (rawJson is String) {
      try {
        json = jsonDecode(rawJson) as Map<String, dynamic>;
      } catch (_) {
        return const PriceSnapshotModel(
          basePrice: 0.0,
          extraFees: 0.0,
          discount: 0.0,
          total: 0.0,
        );
      }
    } else if (rawJson is Map) {
      json = Map<String, dynamic>.from(rawJson);
    } else {
      return const PriceSnapshotModel(
        basePrice: 0.0,
        extraFees: 0.0,
        discount: 0.0,
        total: 0.0,
      );
    }

    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      if (val is String) {
        return double.tryParse(val) ?? 0.0;
      }
      return 0.0;
    }

    final basePrice = parseDouble(json['basePrice'] ?? json['base_price']);
    final extraFees = parseDouble(json['extraFees'] ?? json['extra_fees']);
    final discount = parseDouble(json['discount']);
    final total = parseDouble(json['total'] ?? json['total_amount'] ?? json['totalPrice']);

    Map<String, dynamic>? metadata;
    if (json['metadata'] is Map) {
      metadata = Map<String, dynamic>.from(json['metadata'] as Map);
    } else if (json['metadata'] is String) {
      try {
        metadata = jsonDecode(json['metadata'] as String) as Map<String, dynamic>;
      } catch (_) {}
    }

    return PriceSnapshotModel(
      basePrice: basePrice,
      extraFees: extraFees,
      discount: discount,
      total: total,
      metadata: metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'basePrice': basePrice,
      'extraFees': extraFees,
      'discount': discount,
      'total': total,
      'base_price': basePrice,
      'extra_fees': extraFees,
      if (metadata != null) 'metadata': metadata,
    };
  }
}
