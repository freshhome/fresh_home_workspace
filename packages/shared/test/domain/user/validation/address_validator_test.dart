import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/validation/address_validator.dart';

void main() {
  group('AddressValidator Unit Tests', () {
    final validAddress = Address(
      id: 'addr-1',
      userId: 'user-1',
      governorate: 'Cairo',
      city: 'New Cairo',
      district: 'Fifth Settlement',
      streetOrCompound: 'South 90th Street',
      buildingIdentifier: 'Building 12',
      floor: '3',
      apartmentOrUnit: '302',
      landmark: 'Near Air Force Hospital',
      latitude: 30.0275,
      longitude: 31.4361,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should return right with sanitized address when valid', () {
      final result = AddressValidator.validate(validAddress);
      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('Should not fail'),
        (r) {
          expect(r.governorate, 'Cairo');
          expect(r.city, 'New Cairo');
          expect(r.district, 'Fifth Settlement');
        },
      );
    });

    test('should return left failure when governorate length is less than 2', () {
      final invalid = validAddress.copyWith(governorate: 'A');
      final result = AddressValidator.validate(invalid);
      expect(result.isLeft(), isTrue);
    });

    test('should return left failure when streetOrCompound length is less than 3', () {
      final invalid = validAddress.copyWith(streetOrCompound: 'St');
      final result = AddressValidator.validate(invalid);
      expect(result.isLeft(), isTrue);
    });

    test('should return left failure when latitude is out of range', () {
      final invalid = validAddress.copyWith(latitude: 100.0);
      final result = AddressValidator.validate(invalid);
      expect(result.isLeft(), isTrue);
    });

    test('should return left failure when cityId is provided without governorateId', () {
      final invalid = validAddress.copyWith(cityId: 10, governorateId: null);
      final result = AddressValidator.validate(invalid);
      expect(result.isLeft(), isTrue);
      result.fold((failure) => expect(failure.code, 'INVALID_HIERARCHY'), (_) => fail('Should fail'));
    });

    test('should return left failure when districtId is provided without cityId', () {
      final invalid = validAddress.copyWith(districtId: 100, cityId: null);
      final result = AddressValidator.validate(invalid);
      expect(result.isLeft(), isTrue);
      result.fold((failure) => expect(failure.code, 'INVALID_HIERARCHY'), (_) => fail('Should fail'));
    });

    test('should return right when valid reference IDs are provided in correct hierarchy', () {
      final validRef = validAddress.copyWith(governorateId: 1, cityId: 10, districtId: 100);
      final result = AddressValidator.validate(validRef);
      expect(result.isRight(), isTrue);
    });

    test('should accept boundary values for latitude (-90.0 and 90.0)', () {
      final validMinLat = validAddress.copyWith(latitude: -90.0);
      final resultMin = AddressValidator.validate(validMinLat);
      expect(resultMin.isRight(), isTrue);

      final validMaxLat = validAddress.copyWith(latitude: 90.0);
      final resultMax = AddressValidator.validate(validMaxLat);
      expect(resultMax.isRight(), isTrue);
    });

    test('should accept boundary values for longitude (-180.0 and 180.0)', () {
      final validMinLng = validAddress.copyWith(longitude: -180.0);
      final resultMin = AddressValidator.validate(validMinLng);
      expect(resultMin.isRight(), isTrue);

      final validMaxLng = validAddress.copyWith(longitude: 180.0);
      final resultMax = AddressValidator.validate(validMaxLng);
      expect(resultMax.isRight(), isTrue);
    });

    test('should return left failure when latitude or longitude are unpaired', () {
      final unpairedLat = Address(
        id: 'addr-unpaired-1',
        userId: 'user-1',
        governorate: 'Cairo',
        city: 'New Cairo',
        district: 'Fifth Settlement',
        streetOrCompound: 'Street 90',
        buildingIdentifier: 'Bld 1',
        latitude: 30.0,
        longitude: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final resLat = AddressValidator.validate(unpairedLat);
      expect(resLat.isLeft(), isTrue);
      resLat.fold((f) => expect(f.code, 'UNPAIRED_COORDINATES'), (_) => fail('Should fail'));

      final unpairedLng = Address(
        id: 'addr-unpaired-2',
        userId: 'user-1',
        governorate: 'Cairo',
        city: 'New Cairo',
        district: 'Fifth Settlement',
        streetOrCompound: 'Street 90',
        buildingIdentifier: 'Bld 1',
        latitude: null,
        longitude: 31.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final resLng = AddressValidator.validate(unpairedLng);
      expect(resLng.isLeft(), isTrue);
      resLng.fold((f) => expect(f.code, 'UNPAIRED_COORDINATES'), (_) => fail('Should fail'));
    });

    test('should return left failure when required text fields are empty or whitespace-only', () {
      final emptyGov = validAddress.copyWith(governorate: '   ');
      expect(AddressValidator.validate(emptyGov).isLeft(), isTrue);

      final emptyCity = validAddress.copyWith(city: ' ');
      expect(AddressValidator.validate(emptyCity).isLeft(), isTrue);

      final emptyDistrict = validAddress.copyWith(district: '');
      expect(AddressValidator.validate(emptyDistrict).isLeft(), isTrue);

      final emptyStreet = validAddress.copyWith(streetOrCompound: '  ');
      expect(AddressValidator.validate(emptyStreet).isLeft(), isTrue);

      final emptyBld = validAddress.copyWith(buildingIdentifier: '   ');
      expect(AddressValidator.validate(emptyBld).isLeft(), isTrue);
    });
  });
}


