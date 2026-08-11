import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/booking/mappers/address_snapshot_mapper.dart';
import 'package:shared/data/booking/mappers/booking_mapper.dart';
import 'package:shared/data/booking/models/remote/sub_models/booking_snapshots.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';
import 'package:shared/domain/user/usecases/create_address_usecase.dart';

class MockAddressRepository implements AddressRepository {
  bool createCalled = false;
  Address? lastCreatedAddress;

  @override
  Future<Either<Failure, Address>> createAddress(Address address) async {
    createCalled = true;
    lastCreatedAddress = address;
    return right(address);
  }

  @override
  Future<Either<Failure, Address>> updateAddress(Address address) async => right(address);
  @override
  Future<Either<Failure, void>> deleteAddress(String addressId) async => right(null);
  @override
  Future<Either<Failure, Address>> getAddressById(String addressId) async => throw UnimplementedError();
  @override
  Future<Either<Failure, List<Address>>> getAddresses(String userId) async => right([]);
  @override
  Future<Either<Failure, Address?>> getPrimaryAddress(String userId) async => right(null);
  @override
  Future<Either<Failure, void>> setPrimaryAddress({required String userId, required String addressId}) async => right(null);
}

void main() {
  group('Phase 5.1 — Address Booking Pipeline End-to-End Integration Tests', () {
    late MockAddressRepository mockRepository;
    late CreateAddressUseCase createAddressUseCase;

    setUp(() {
      mockRepository = MockAddressRepository();
      createAddressUseCase = CreateAddressUseCase(mockRepository);
    });

    final validBilingualAddress = Address(
      id: 'addr-e2e-1',
      userId: 'user-e2e-100',
      governorate: 'القاهرة',
      city: 'مدينة نصر',
      district: 'الحي الأول',
      governorateId: 1,
      cityId: 10,
      districtId: 100,
      governorateAr: 'القاهرة',
      governorateEn: 'Cairo',
      cityAr: 'مدينة نصر',
      cityEn: 'Nasr City',
      districtAr: 'الحي الأول',
      districtEn: 'First District',
      streetOrCompound: 'شارع الطيران',
      buildingIdentifier: 'مبنى 15',
      floor: '3',
      apartmentOrUnit: '301',
      landmark: 'بجوار المسجد الكبير',
      propertyType: 'residential',
      latitude: 30.0500,
      longitude: 31.3333,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('Scenario 1 — End-to-End Arabic Address Pipeline Verification', () async {
      // Step 1: Execute CreateAddressUseCase through domain validation
      final createResult = await createAddressUseCase(validBilingualAddress);
      expect(createResult.isRight(), isTrue);
      expect(mockRepository.createCalled, isTrue);

      final savedAddress = mockRepository.lastCreatedAddress!;
      expect(savedAddress.governorateId, equals(1));
      expect(savedAddress.cityId, equals(10));
      expect(savedAddress.districtId, equals(100));

      // Step 2: Build Address Snapshot V2 JSON
      final snapshotJson = AddressSnapshotMapper.buildSnapshotJson(savedAddress);

      // Step 3: Verify Version 2 contract fields in JSON
      expect(snapshotJson['snapshot_version'], equals(2));
      final addressData = snapshotJson['address'] as Map<String, dynamic>;
      expect(addressData['address_id'], equals('addr-e2e-1'));
      expect(addressData['governorate_id'], equals(1));
      expect(addressData['city_id'], equals(10));
      expect(addressData['district_id'], equals(100));
      expect(addressData['governorate_ar'], equals('القاهرة'));
      expect(addressData['governorate_en'], equals('Cairo'));
      expect(addressData['city_ar'], equals('مدينة نصر'));
      expect(addressData['city_en'], equals('Nasr City'));
      expect(addressData['district_ar'], equals('الحي الأول'));
      expect(addressData['district_en'], equals('First District'));

      // Step 4: Map through BookingSnapshotModel & BookingMapper
      final snapshotModel = AddressSnapshotModel.fromJson(snapshotJson);
      final bookingAddressEntity = BookingMapper.addressSnapshotToEntity(snapshotModel);

      // Step 5: Verify offline Arabic display from parsed snapshot
      expect(bookingAddressEntity.getGovernorateName('ar'), equals('القاهرة'));
      expect(bookingAddressEntity.getCityName('ar'), equals('مدينة نصر'));
      expect(bookingAddressEntity.getDistrictName('ar'), equals('الحي الأول'));
    });

    test('Scenario 2 — End-to-End English Address Pipeline Verification', () async {
      // Step 1: Execute CreateAddressUseCase
      final createResult = await createAddressUseCase(validBilingualAddress);
      expect(createResult.isRight(), isTrue);

      // Step 2: Build Snapshot V2 & map through BookingSnapshotModel
      final snapshotJson = AddressSnapshotMapper.buildSnapshotJson(validBilingualAddress);
      final snapshotModel = AddressSnapshotModel.fromJson(snapshotJson);
      final bookingAddressEntity = BookingMapper.addressSnapshotToEntity(snapshotModel);

      // Step 3: Verify offline English display directly from snapshot
      expect(bookingAddressEntity.getGovernorateName('en'), equals('Cairo'));
      expect(bookingAddressEntity.getCityName('en'), equals('Nasr City'));
      expect(bookingAddressEntity.getDistrictName('en'), equals('First District'));
    });

    test('Scenario 3 — Validation Boundary & Execution Interruption Verification', () async {
      // Test Hierarchy Failure 1: cityId provided without governorateId
      final invalidAddressCityNoGov = Address(
        id: 'addr-invalid-1',
        userId: 'user-e2e-100',
        governorate: 'القاهرة',
        city: 'مدينة نصر',
        district: 'الحي الأول',
        governorateId: null,
        cityId: 10,
        districtId: 100,
        streetOrCompound: 'شارع الطيران',
        buildingIdentifier: 'مبنى 15',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result1 = await createAddressUseCase(invalidAddressCityNoGov);
      expect(result1.isLeft(), isTrue);
      expect(mockRepository.createCalled, isFalse);
      result1.fold(
        (failure) => expect(failure.code, equals('INVALID_HIERARCHY')),
        (_) => fail('Should have failed validation'),
      );

      // Test Hierarchy Failure 2: districtId provided without cityId
      final invalidAddressDistrictNoCity = Address(
        id: 'addr-invalid-2',
        userId: 'user-e2e-100',
        governorate: 'القاهرة',
        city: 'مدينة نصر',
        district: 'الحي الأول',
        governorateId: 1,
        cityId: null,
        districtId: 100,
        streetOrCompound: 'شارع الطيران',
        buildingIdentifier: 'مبنى 15',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result2 = await createAddressUseCase(invalidAddressDistrictNoCity);
      expect(result2.isLeft(), isTrue);
      expect(mockRepository.createCalled, isFalse);
      result2.fold(
        (failure) => expect(failure.code, equals('INVALID_HIERARCHY')),
        (_) => fail('Should have failed validation'),
      );
    });


    test('Scenario 4 — Snapshot Round-Trip & Historical Immutability Verification', () async {
      // Step 1: Create V2 Snapshot at booking creation time
      final initialSnapshotJson = AddressSnapshotMapper.buildSnapshotJson(
        validBilingualAddress,
        governorateAr: 'القاهرة',
        governorateEn: 'Cairo',
        cityAr: 'مدينة نصر',
        cityEn: 'Nasr City',
        districtAr: 'الحي الأول',
        districtEn: 'First District',
      );

      // Step 2: Simulate future live DB reference table renaming (e.g., Cairo -> Greater Cairo in reference DB)
      // The stored initialSnapshotJson represents historical DB record.

      // Step 3: Reconstruct Address entity strictly from historical snapshot
      final historicalAddress = AddressSnapshotMapper.parseSnapshotJson(initialSnapshotJson);

      // Step 4: Verify historical names remain 100% immutable and match creation time
      expect(historicalAddress.getGovernorateName('ar'), equals('القاهرة'));
      expect(historicalAddress.getGovernorateName('en'), equals('Cairo'));
      expect(historicalAddress.getCityName('ar'), equals('مدينة نصر'));
      expect(historicalAddress.getCityName('en'), equals('Nasr City'));
      expect(historicalAddress.getDistrictName('ar'), equals('الحي الأول'));
      expect(historicalAddress.getDistrictName('en'), equals('First District'));
    });

    test('Scenario 5 — Backward Compatibility Pipeline Verification (V1 & Legacy Flat)', () async {
      // Part A: Version 1 Snapshot Pipeline
      final v1SnapshotJson = {
        'snapshot_version': 1,
        'address': {
          'address_id': 'addr-v1-test',
          'user_id': 'user-v1-test',
          'governorate': 'Cairo',
          'city': 'New Cairo',
          'district': 'Fifth Settlement',
          'street_or_compound': '90th South Street',
          'building_identifier': 'Building 10',
          'floor': '2',
          'apartment_or_unit': '201',
        }
      };

      final parsedV1Address = AddressSnapshotMapper.parseSnapshotJson(v1SnapshotJson);
      expect(parsedV1Address.id, equals('addr-v1-test'));
      expect(parsedV1Address.governorate, equals('Cairo'));
      expect(parsedV1Address.city, equals('New Cairo'));
      expect(parsedV1Address.district, equals('Fifth Settlement'));
      expect(parsedV1Address.streetOrCompound, equals('90th South Street'));
      expect(parsedV1Address.getGovernorateName('en'), equals('Cairo'));
      expect(parsedV1Address.getGovernorateName('ar'), equals('Cairo'));

      // Part B: Legacy Flat JSON Pipeline
      final legacyFlatJson = {
        'id': 'flat-legacy-99',
        'governorate': 'Giza',
        'city': 'Dokki',
        'district': 'Mosaddak',
        'street': 'Iran Street',
        'building_number': '7',
      };

      final parsedFlatAddress = AddressSnapshotMapper.parseSnapshotJson(legacyFlatJson);
      expect(parsedFlatAddress.id, equals('flat-legacy-99'));
      expect(parsedFlatAddress.governorate, equals('Giza'));
      expect(parsedFlatAddress.city, equals('Dokki'));
      expect(parsedFlatAddress.district, equals('Mosaddak'));
      expect(parsedFlatAddress.streetOrCompound, equals('Iran Street'));
      expect(parsedFlatAddress.buildingIdentifier, equals('7'));
    });
  });
}
