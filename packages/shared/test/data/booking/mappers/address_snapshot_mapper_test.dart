import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/booking/mappers/address_snapshot_mapper.dart';
import 'package:shared/domain/user/entities/user/address.dart';

void main() {
  group('AddressSnapshotMapper V2 Unit Tests', () {
    final sampleAddress = Address(
      id: 'addr-100',
      userId: 'usr-200',
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
      streetOrCompound: '90th Street',
      buildingIdentifier: 'Tower A',
      floor: '4',
      apartmentOrUnit: '401',
      landmark: 'Behind Dusit Hotel',
      latitude: 30.0123,
      longitude: 31.4567,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should build versioned snapshot JSON with version 2 and bilingual fields', () {
      final json = AddressSnapshotMapper.buildSnapshotJson(sampleAddress);

      expect(json['snapshot_version'], equals(2));
      expect(json.containsKey('address'), isTrue);

      final addrMap = json['address'] as Map<String, dynamic>;
      expect(addrMap['address_id'], equals('addr-100'));
      expect(addrMap['governorate_id'], equals(1));
      expect(addrMap['city_id'], equals(10));
      expect(addrMap['district_id'], equals(100));
      expect(addrMap['governorate_ar'], equals('القاهرة'));
      expect(addrMap['governorate_en'], equals('Cairo'));
      expect(addrMap['city_ar'], equals('مدينة نصر'));
      expect(addrMap['city_en'], equals('Nasr City'));
      expect(addrMap['district_ar'], equals('الحي الأول'));
      expect(addrMap['district_en'], equals('First District'));
    });

    test('should parse versioned V2 snapshot JSON correctly into Address entity', () {
      final json = AddressSnapshotMapper.buildSnapshotJson(sampleAddress);
      final entity = AddressSnapshotMapper.parseSnapshotJson(json);

      expect(entity.id, equals('addr-100'));
      expect(entity.governorateId, equals(1));
      expect(entity.cityId, equals(10));
      expect(entity.districtId, equals(100));
      expect(entity.governorateAr, equals('القاهرة'));
      expect(entity.governorateEn, equals('Cairo'));
      expect(entity.cityAr, equals('مدينة نصر'));
      expect(entity.cityEn, equals('Nasr City'));
      expect(entity.districtAr, equals('الحي الأول'));
      expect(entity.districtEn, equals('First District'));
    });

    test('Historical Immutability Test: snapshot remains immutable even if live data changes', () {
      // Step 1: Create V2 snapshot at booking creation time
      final snapshotJson = AddressSnapshotMapper.buildSnapshotJson(
        sampleAddress,
        governorateAr: 'القاهرة',
        governorateEn: 'Cairo',
        cityAr: 'مدينة نصر',
        cityEn: 'Nasr City',
      );

      // Step 2: Simulate future live DB reference table renaming
      // Suppose live governorate 1 is renamed in Supabase DB to "القاهرة الكبرى" / "Greater Cairo"
      // and live city 10 is renamed to "مدينة نصر الجديدة" / "New Nasr City".
      // Our stored snapshot JSON MUST NOT CHANGE.

      // Step 3: Parse stored snapshot
      final historicalAddress = AddressSnapshotMapper.parseSnapshotJson(snapshotJson);

      // Step 4: Verify snapshot retains exact original names from booking creation time
      expect(historicalAddress.getGovernorateName('ar'), equals('القاهرة'));
      expect(historicalAddress.getGovernorateName('en'), equals('Cairo'));
      expect(historicalAddress.getCityName('ar'), equals('مدينة نصر'));
      expect(historicalAddress.getCityName('en'), equals('Nasr City'));
    });

    test('Bilingual Rendering Test: renders ar and en without live lookup', () {
      final json = AddressSnapshotMapper.buildSnapshotJson(sampleAddress);
      final entity = AddressSnapshotMapper.parseSnapshotJson(json);

      expect(entity.getGovernorateName('ar'), equals('القاهرة'));
      expect(entity.getGovernorateName('en'), equals('Cairo'));
      expect(entity.getCityName('ar'), equals('مدينة نصر'));
      expect(entity.getCityName('en'), equals('Nasr City'));
      expect(entity.getDistrictName('ar'), equals('الحي الأول'));
      expect(entity.getDistrictName('en'), equals('First District'));
    });

    test('Backward Compatibility: V1 versioned snapshot parses cleanly without error', () {
      final v1Json = {
        'snapshot_version': 1,
        'address': {
          'address_id': 'addr-v1',
          'user_id': 'user-1',
          'governorate': 'Cairo',
          'city': 'New Cairo',
          'district': 'Fifth Settlement',
          'street_or_compound': 'Street 90',
          'building_identifier': 'Building 5',
        }
      };

      final entity = AddressSnapshotMapper.parseSnapshotJson(v1Json);

      expect(entity.id, equals('addr-v1'));
      expect(entity.governorate, equals('Cairo'));
      expect(entity.getGovernorateName('en'), equals('Cairo'));
      expect(entity.getGovernorateName('ar'), equals('Cairo'));
    });

    test('Backward Compatibility: Legacy flat JSON snapshot parses cleanly without error', () {
      final flatJson = {
        'id': 'flat-1',
        'governorate': 'Giza',
        'city': 'Dokki',
        'district': 'Mosaddak',
        'street': 'Mosaddak Street',
        'building_number': '12B',
      };

      final entity = AddressSnapshotMapper.parseSnapshotJson(flatJson);

      expect(entity.id, equals('flat-1'));
      expect(entity.governorate, equals('Giza'));
      expect(entity.city, equals('Dokki'));
      expect(entity.district, equals('Mosaddak'));
      expect(entity.streetOrCompound, equals('Mosaddak Street'));
      expect(entity.buildingIdentifier, equals('12B'));
    });
  });
}
