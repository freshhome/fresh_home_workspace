import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/services/address_formatter.dart';

void main() {
  group('AddressFormatter Unit Tests', () {
    final sampleAddress = Address(
      id: 'addr-55',
      userId: 'usr-88',
      governorate: 'Giza',
      city: '6th of October',
      district: 'District 1',
      streetOrCompound: 'Beverly Hills Compound',
      buildingIdentifier: 'Villa 12',
      floor: 'Ground',
      apartmentOrUnit: 'Unit 1',
      landmark: 'Gate 2',
      latitude: 29.9876,
      longitude: 30.9876,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('toSingleLine should return clean single line text', () {
      final singleLine = AddressFormatter.toSingleLine(sampleAddress);
      expect(singleLine, contains('District 1'));
      expect(singleLine, contains('Beverly Hills Compound'));
      expect(singleLine, contains('Villa 12'));
      expect(singleLine, contains('Giza'));
    });

    test('toShortSummary should return concise header text', () {
      final summary = AddressFormatter.toShortSummary(sampleAddress);
      expect(summary, equals('District 1 - Beverly Hills Compound (Villa 12)'));
    });

    test('toGoogleMapsQuery should prefer coordinates if available', () {
      final query = AddressFormatter.toGoogleMapsQuery(sampleAddress);
      expect(query, equals('29.9876,30.9876'));
    });

    test('toTechnicianSummary should format last-100m delivery info', () {
      final summary = AddressFormatter.toTechnicianSummary(sampleAddress);
      expect(summary, contains('Bldg: Villa 12'));
      expect(summary, contains('Floor: Ground'));
      expect(summary, contains('Landmark: Gate 2'));
    });
  });
}
