import 'package:shared/domain/user/entities/user/address.dart';

/// Mapper enforcing the Immutable Versioned Address Snapshot contract for Bookings.
/// Spec Reference: docs/address_system_v2_specification.md Section 7
class AddressSnapshotMapper {
  static const int currentSnapshotVersion = 2;

  /// Builds a versioned, immutable JSON snapshot of an Address for embedding in a Booking.
  /// Snapshot V2 stores reference IDs as well as immutable bilingual names (governorate_ar/en, city_ar/en, district_ar/en).
  static Map<String, dynamic> buildSnapshotJson(
    Address address, {
    String? governorateAr,
    String? governorateEn,
    String? cityAr,
    String? cityEn,
    String? districtAr,
    String? districtEn,
  }) {
    final govAr = governorateAr ?? address.governorateAr ?? address.governorate;
    final govEn = governorateEn ?? address.governorateEn ?? address.governorate;
    final cAr = cityAr ?? address.cityAr ?? address.city;
    final cEn = cityEn ?? address.cityEn ?? address.city;
    final dAr = districtAr ?? address.districtAr ?? address.district;
    final dEn = districtEn ?? address.districtEn ?? address.district;

    return {
      'snapshot_version': currentSnapshotVersion,
      'address': {
        'address_id': address.id,
        'user_id': address.userId,
        'governorate': address.governorate,
        'city': address.city,
        'district': address.district,
        if (address.governorateId != null) 'governorate_id': address.governorateId,
        if (address.cityId != null) 'city_id': address.cityId,
        if (address.districtId != null) 'district_id': address.districtId,
        'governorate_ar': govAr,
        'governorate_en': govEn,
        'city_ar': cAr,
        'city_en': cEn,
        'district_ar': dAr,
        'district_en': dEn,
        'street_or_compound': address.streetOrCompound,
        'building_identifier': address.buildingIdentifier,
        'floor': address.floor,
        'apartment_or_unit': address.apartmentOrUnit,
        'landmark': address.landmark,
        'property_type': address.propertyType,
        'latitude': address.latitude,
        'longitude': address.longitude,
        'snapshot_created_at': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Parses an embedded JSON address snapshot from a Booking record.
  /// Handles forward and backward compatibility (Legacy flat, V1, V2).
  static Address parseSnapshotJson(Map<String, dynamic> json) {
    Map<String, dynamic> addressData;
    if (json.containsKey('address') && json['address'] is Map) {
      addressData = Map<String, dynamic>.from(json['address'] as Map);
    } else {
      // Legacy or flat fallback
      addressData = json;
    }

    final govAr = addressData['governorate_ar'] as String?;
    final govEn = addressData['governorate_en'] as String?;
    final cAr = addressData['city_ar'] as String?;
    final cEn = addressData['city_en'] as String?;
    final dAr = addressData['district_ar'] as String?;
    final dEn = addressData['district_en'] as String?;

    return Address(
      id: addressData['address_id'] as String? ?? addressData['id'] as String? ?? '',
      userId: addressData['user_id'] as String? ?? '',
      governorate: addressData['governorate'] as String? ?? govAr ?? govEn ?? '',
      city: addressData['city'] as String? ?? cAr ?? cEn ?? '',
      district: addressData['district'] as String? ?? dAr ?? dEn ?? '',
      governorateId: (addressData['governorate_id'] as num?)?.toInt(),
      cityId: (addressData['city_id'] as num?)?.toInt(),
      districtId: (addressData['district_id'] as num?)?.toInt(),
      governorateAr: govAr,
      governorateEn: govEn,
      cityAr: cAr,
      cityEn: cEn,
      districtAr: dAr,
      districtEn: dEn,
      streetOrCompound: addressData['street_or_compound'] as String? ?? addressData['street'] as String? ?? '',
      buildingIdentifier: addressData['building_identifier'] as String? ?? addressData['building_number'] as String? ?? '',
      floor: addressData['floor'] as String?,
      apartmentOrUnit: addressData['apartment_or_unit'] as String? ?? addressData['apartment'] as String?,
      landmark: addressData['landmark'] as String?,
      propertyType: addressData['property_type'] as String? ?? addressData['propertyType'] as String?,
      latitude: (addressData['latitude'] as num?)?.toDouble(),
      longitude: (addressData['longitude'] as num?)?.toDouble(),
      isPrimary: false,
      createdAt: addressData['snapshot_created_at'] != null 
          ? DateTime.parse(addressData['snapshot_created_at'] as String)
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

