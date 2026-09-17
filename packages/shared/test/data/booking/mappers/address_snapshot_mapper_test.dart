import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/booking/mappers/address_snapshot_mapper.dart';
import 'package:shared/domain/user/entities/user/address.dart';

void main() {
  group('AddressSnapshotMapper V3 Unit Tests', () {
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
      addressDetails: 'شارع التسعين، مبنى Tower A، الدور 4، شقة 401 (بجوار فندق دوسيت)',
      latitude: 30.0123,
      longitude: 31.4567,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should build versioned snapshot JSON with version 3', () {
      final json = AddressSnapshotMapper.buildSnapshotJson(sampleAddress);

      expect(json['snapshot_version'], equals(3));
      expect(json['governorate'], equals('القاهرة'));
      expect(json['city'], equals('مدينة نصر'));
      expect(json['district'], equals('الحي الأول'));
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
      expect(addrMap.containsKey('address_details'), isTrue);
      expect(addrMap['address_details'], contains('Tower A'));
    });

    test('should parse versioned V3 snapshot JSON correctly into Address entity', () {
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
      expect(entity.addressDetails, contains('Tower A'));
    });

    test('Historical Immutability Test: snapshot remains immutable even if live data changes', () {
      final snapshotJson = AddressSnapshotMapper.buildSnapshotJson(
        sampleAddress,
        governorateAr: 'القاهرة',
        governorateEn: 'Cairo',
        cityAr: 'مدينة نصر',
        cityEn: 'Nasr City',
      );

      final historicalAddress = AddressSnapshotMapper.parseSnapshotJson(snapshotJson);

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

    test('Backward Compatibility V2: parses V2 snapshot with street/building fields', () {
      final v2Json = {
        'snapshot_version': 2,
        'address': {
          'address_id': 'addr-v2',
          'user_id': 'user-1',
          'governorate': 'Cairo',
          'city': 'New Cairo',
          'district': 'Fifth Settlement',
          'street_or_compound': '90th Street',
          'building_identifier': 'Building 5',
          'floor': '3',
          'apartment_or_unit': '302',
          'landmark': 'Near Air Force Hospital',
        }
      };

      final entity = AddressSnapshotMapper.parseSnapshotJson(v2Json);

      expect(entity.id, equals('addr-v2'));
      expect(entity.governorate, equals('Cairo'));
      // V3 fallback: addressDetails reconstructed from V2 fields
      expect(entity.addressDetails, contains('90th Street'));
      expect(entity.addressDetails, contains('Building 5'));
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
      // V3 fallback: reconstructed from legacy street + building fields
      expect(entity.addressDetails, contains('Mosaddak Street'));
      expect(entity.addressDetails, contains('12B'));
    });
  });
}
