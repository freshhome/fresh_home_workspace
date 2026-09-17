import 'package:shared/domain/user/entities/user/address.dart';

/// Mapper enforcing the Immutable Versioned Address Snapshot contract for Bookings.
/// Spec Reference: docs/address_system_v2_specification.md Section 7
/// V3: Replaces fragmented street/building/floor/apartment/landmark with [addressDetails].
class AddressSnapshotMapper {
  static const int currentSnapshotVersion = 3;

  /// Builds a versioned, immutable JSON snapshot of an Address for embedding in a Booking.
  /// Snapshot V3 stores governorate/city/district + unified addressDetails + optional location.
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

    final resolvedGovAr = (govAr.toLowerCase().contains('giza')
        ? 'الجيزة'
        : (govAr.toLowerCase().contains('cairo') ? 'القاهرة' : govAr));

    return {
      'snapshot_version': currentSnapshotVersion,
      'governorate': resolvedGovAr,
      'city': cAr,
      'district': dAr,
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
        'address_details': address.addressDetails,
        if (address.locationUrl != null && address.locationUrl!.isNotEmpty)
          'location_url': address.locationUrl,
        if (address.latitude != null) 'latitude': address.latitude,
        if (address.longitude != null) 'longitude': address.longitude,
        'snapshot_created_at': DateTime.now().toIso8601String(),
      },
    };
  }

  /// Parses an embedded JSON address snapshot from a Booking record.
  /// Handles forward and backward compatibility (Legacy flat, V1, V2, V3).
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

    // V3 → V2 legacy fallback: reconstruct addressDetails from old fields if needed.
    final rawAddressDetails = addressData['address_details'] as String?;
    final legacyStreet = addressData['street_or_compound'] as String? ?? addressData['street'] as String? ?? '';
    final legacyBuilding = addressData['building_identifier'] as String? ?? addressData['building_number'] as String? ?? '';
    final legacyFloor = addressData['floor'] as String?;
    final legacyApartment = addressData['apartment_or_unit'] as String? ?? addressData['apartment'] as String?;
    final legacyLandmark = addressData['landmark'] as String?;

    final addressDetails = rawAddressDetails?.isNotEmpty == true
        ? rawAddressDetails!
        : _reconstructAddressDetails(
            street: legacyStreet,
            building: legacyBuilding,
            floor: legacyFloor,
            apartment: legacyApartment,
            landmark: legacyLandmark,
          );

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
      addressDetails: addressDetails,
      locationUrl: addressData['location_url'] as String? ?? addressData['locationUrl'] as String?,
      latitude: (addressData['latitude'] as num?)?.toDouble(),
      longitude: (addressData['longitude'] as num?)?.toDouble(),
      isPrimary: false,
      createdAt: addressData['snapshot_created_at'] != null
          ? DateTime.parse(addressData['snapshot_created_at'] as String)
          : DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Reconstructs a readable address_details string from legacy V2 snapshot fields.
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
