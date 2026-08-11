import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';

/// Domain Validator enforcing architectural validation rules for Address System V2.
class AddressValidator {
  static Either<ValidationFailure, Address> validate(Address address) {
    final governorate = address.governorate.trim();
    if (governorate.length < 2 || governorate.length > 100) {
      return left(const ValidationFailure(
        message: 'Governorate must be between 2 and 100 characters.',
        code: 'INVALID_GOVERNORATE',
      ));
    }

    final city = address.city.trim();
    if (city.length < 2 || city.length > 100) {
      return left(const ValidationFailure(
        message: 'City must be between 2 and 100 characters.',
        code: 'INVALID_CITY',
      ));
    }

    final district = address.district.trim();
    if (district.length < 2 || district.length > 100) {
      return left(const ValidationFailure(
        message: 'District must be between 2 and 100 characters.',
        code: 'INVALID_DISTRICT',
      ));
    }

    final streetOrCompound = address.streetOrCompound.trim();
    if (streetOrCompound.length < 3 || streetOrCompound.length > 255) {
      return left(const ValidationFailure(
        message: 'Street / Compound must be between 3 and 255 characters.',
        code: 'INVALID_STREET_OR_COMPOUND',
      ));
    }

    final buildingIdentifier = address.buildingIdentifier.trim();
    if (buildingIdentifier.isEmpty || buildingIdentifier.length > 100) {
      return left(const ValidationFailure(
        message: 'Building identifier must be between 1 and 100 characters.',
        code: 'INVALID_BUILDING_IDENTIFIER',
      ));
    }

    if (address.floor != null && address.floor!.trim().length > 50) {
      return left(const ValidationFailure(
        message: 'Floor cannot exceed 50 characters.',
        code: 'INVALID_FLOOR',
      ));
    }

    if (address.apartmentOrUnit != null && address.apartmentOrUnit!.trim().length > 50) {
      return left(const ValidationFailure(
        message: 'Apartment / Unit cannot exceed 50 characters.',
        code: 'INVALID_APARTMENT_OR_UNIT',
      ));
    }

    if (address.landmark != null && address.landmark!.trim().length > 255) {
      return left(const ValidationFailure(
        message: 'Landmark cannot exceed 255 characters.',
        code: 'INVALID_LANDMARK',
      ));
    }

    if (address.latitude != null) {
      if (address.latitude! < -90.0 || address.latitude! > 90.0) {
        return left(const ValidationFailure(
          message: 'Latitude must be between -90.0 and 90.0.',
          code: 'INVALID_LATITUDE',
        ));
      }
    }

    if (address.longitude != null) {
      if (address.longitude! < -180.0 || address.longitude! > 180.0) {
        return left(const ValidationFailure(
          message: 'Longitude must be between -180.0 and 180.0.',
          code: 'INVALID_LONGITUDE',
        ));
      }
    }

    if ((address.latitude != null && address.longitude == null) ||
        (address.longitude != null && address.latitude == null)) {
      return left(const ValidationFailure(
        message: 'Latitude and Longitude must both be provided together or both be null.',
        code: 'UNPAIRED_COORDINATES',
      ));
    }

    if (address.cityId != null && address.governorateId == null) {

      return left(const ValidationFailure(
        message: 'City ID cannot be provided without Governorate ID.',
        code: 'INVALID_HIERARCHY',
      ));
    }

    if (address.districtId != null && address.cityId == null) {
      return left(const ValidationFailure(
        message: 'District ID cannot be provided without City ID.',
        code: 'INVALID_HIERARCHY',
      ));
    }

    // Return sanitized address object with trimmed strings
    return right(address.copyWith(
      governorate: governorate,
      city: city,
      district: district,
      streetOrCompound: streetOrCompound,
      buildingIdentifier: buildingIdentifier,
      floor: address.floor?.trim(),
      apartmentOrUnit: address.apartmentOrUnit?.trim(),
      landmark: address.landmark?.trim(),
    ));
  }
}
