import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/booking/mappers/address_snapshot_mapper.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/location/cubit/location_picker_cubit.dart';
import 'package:shared/presentation/location/cubit/location_picker_state.dart';

void main() {
  group('LocationPickerCubit & Step 3 Map Experience Unit Tests', () {
    late LocationPickerCubit cubit;

    setUp(() {
      cubit = LocationPickerCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('Test 1 — LocationPickerCubit initializes with null or initial coordinates', () {
      expect(cubit.state.latitude, isNull);
      expect(cubit.state.longitude, isNull);
      expect(cubit.state.hasCoordinates, isFalse);

      final cubitWithCoords = LocationPickerCubit(initialLatitude: 30.0444, initialLongitude: 31.2357);
      expect(cubitWithCoords.state.latitude, equals(30.0444));
      expect(cubitWithCoords.state.longitude, equals(31.2357));
      expect(cubitWithCoords.state.hasCoordinates, isTrue);
      cubitWithCoords.close();
    });

    test('Test 2 & 3 — Selecting location produces valid latitude + longitude and updates marker position', () {
      final res = cubit.selectLocation(latitude: 30.0500, longitude: 31.3333);
      expect(res.isRight(), isTrue);
      expect(cubit.state.latitude, equals(30.0500));
      expect(cubit.state.longitude, equals(31.3333));
      expect(cubit.state.hasCoordinates, isTrue);

      // Move marker to new position
      final resMove = cubit.selectLocation(latitude: 30.0600, longitude: 31.3400);
      expect(resMove.isRight(), isTrue);
      expect(cubit.state.latitude, equals(30.0600));
      expect(cubit.state.longitude, equals(31.3400));
    });

    test('Test 4 — Existing coordinates restore correctly on Edit', () {
      final editCubit = LocationPickerCubit(initialLatitude: 29.9800, initialLongitude: 31.1300);
      expect(editCubit.state.latitude, equals(29.9800));
      expect(editCubit.state.longitude, equals(31.1300));
      editCubit.close();
    });

    test('Test 5 — Clearing location resets both latitude and longitude to null simultaneously', () {
      cubit.selectLocation(latitude: 30.0, longitude: 31.0);
      expect(cubit.state.hasCoordinates, isTrue);

      cubit.clearLocation();
      expect(cubit.state.latitude, isNull);
      expect(cubit.state.longitude, isNull);
      expect(cubit.state.hasCoordinates, isFalse);
    });

    test('Test 6 — Out-of-range coordinates are rejected by validation', () {
      final invalidLat = cubit.selectLocation(latitude: 100.0, longitude: 31.0);
      expect(invalidLat.isLeft(), isTrue);
      invalidLat.fold((failure) => expect(failure.code, equals('INVALID_LATITUDE')), (_) => fail('Should fail'));

      final invalidLng = cubit.selectLocation(latitude: 30.0, longitude: 200.0);
      expect(invalidLng.isLeft(), isTrue);
      invalidLng.fold((failure) => expect(failure.code, equals('INVALID_LONGITUDE')), (_) => fail('Should fail'));
    });

    test('Test 7 & 8 — Current location request with mock provider updates coordinates and permission status', () async {
      await cubit.requestCurrentLocation(
        mockLocationProvider: () async => {'latitude': 30.0444, 'longitude': 31.2357},
      );

      expect(cubit.state.latitude, equals(30.0444));
      expect(cubit.state.longitude, equals(31.2357));
      expect(cubit.state.permissionStatus, equals(LocationPermissionStatus.granted));
      expect(cubit.state.isLoadingLocation, isFalse);
    });

    test('Test 9 & 10 — Create/Update Address persists coordinates in Address entity', () {
      final addressWithGps = Address(
        id: 'addr-gps-1',
        userId: 'user-1',
        governorate: 'Cairo',
        city: 'Nasr City',
        district: 'First District',
        streetOrCompound: 'Tayaran Street',
        buildingIdentifier: '15',
        latitude: 30.0500,
        longitude: 31.3333,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(addressWithGps.hasCoordinates, isTrue);
      expect(addressWithGps.latitude, equals(30.0500));
      expect(addressWithGps.longitude, equals(31.3333));
    });

    test('Test 11 — Booking Snapshot V2 remains 100% valid and preserves coordinates', () {
      final addressWithGps = Address(
        id: 'addr-gps-snapshot',
        userId: 'user-1',
        governorate: 'Cairo',
        city: 'Nasr City',
        district: 'First District',
        governorateId: 1,
        cityId: 10,
        districtId: 100,
        governorateAr: 'القاهرة',
        governorateEn: 'Cairo',
        cityAr: 'مدينة نصر',
        cityEn: 'Nasr City',
        districtAr: 'الحي الأول',
        districtEn: 'First District',
        streetOrCompound: 'Tayaran Street',
        buildingIdentifier: '15',
        latitude: 30.0500,
        longitude: 31.3333,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final snapshotJson = AddressSnapshotMapper.buildSnapshotJson(addressWithGps);
      expect(snapshotJson['snapshot_version'], equals(2));

      final parsedAddress = AddressSnapshotMapper.parseSnapshotJson(snapshotJson);
      expect(parsedAddress.hasCoordinates, isTrue);
      expect(parsedAddress.latitude, equals(30.0500));
      expect(parsedAddress.longitude, equals(31.3333));
    });
  });
}
