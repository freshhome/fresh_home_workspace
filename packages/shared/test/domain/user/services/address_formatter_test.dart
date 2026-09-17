import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/services/address_formatter.dart';

void main() {
  group('AddressFormatter Unit Tests (V3)', () {
    final sampleAddress = Address(
      id: 'addr-55',
      userId: 'usr-88',
      governorate: 'Giza',
      city: '6th of October',
      district: 'District 1',
      addressDetails: 'Beverly Hills Compound, Villa 12, Gate 2',
      latitude: 29.9876,
      longitude: 30.9876,
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final sampleAddressNoCoords = Address(
      id: 'addr-55-no-coords',
      userId: 'usr-88',
      governorate: 'Giza',
      city: '6th of October',
      district: 'District 1',
      addressDetails: 'Beverly Hills Compound, Villa 12, Gate 2',
      isPrimary: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('toSingleLine should return district + city + addressDetails', () {
      final singleLine = AddressFormatter.toSingleLine(sampleAddress);
      expect(singleLine, contains('District 1'));
      expect(singleLine, contains('Beverly Hills Compound'));
    });

    test('toShortSummary should return district - addressDetails', () {
      final summary = AddressFormatter.toShortSummary(sampleAddress);
      expect(summary, contains('District 1'));
      expect(summary, contains('Beverly Hills Compound'));
    });

    test('toGoogleMapsQuery should prefer coordinates if available', () {
      final query = AddressFormatter.toGoogleMapsQuery(sampleAddress);
      expect(query, equals('29.9876,30.9876'));
    });

    test('toGoogleMapsQuery should use geographic text when no coordinates', () {
      final query = AddressFormatter.toGoogleMapsQuery(sampleAddressNoCoords);
      expect(query, contains('District 1'));
      expect(query, contains('6th of October'));
      expect(query, contains('Giza'));
    });

    test('toTechnicianSummary should return addressDetails directly', () {
      final summary = AddressFormatter.toTechnicianSummary(sampleAddress);
      expect(summary, equals('Beverly Hills Compound, Villa 12, Gate 2'));
    });

    test('toMultiLine should include addressDetails and geographic hierarchy', () {
      final multiLine = AddressFormatter.toMultiLine(sampleAddress);
      expect(multiLine, contains('Beverly Hills Compound'));
      expect(multiLine, contains('Giza'));
    });
  });
}
