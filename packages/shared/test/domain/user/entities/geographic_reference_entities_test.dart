import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';

void main() {
  group('Geographic Reference Entities Unit Tests', () {
    test('Governorate getName should return Arabic or English name based on locale', () {
      const gov = Governorate(
        id: 1,
        nameAr: 'القاهرة',
        nameEn: 'Cairo',
        code: 'CAI',
      );

      expect(gov.getName('ar'), equals('القاهرة'));
      expect(gov.getName('en'), equals('Cairo'));
      expect(gov.getName('EN-US'), equals('Cairo'));
    });

    test('City getName should return Arabic or English name based on locale', () {
      const city = City(
        id: 105,
        governorateId: 1,
        nameAr: 'التجمع الخامس',
        nameEn: 'Fifth Settlement',
      );

      expect(city.getName('ar'), equals('التجمع الخامس'));
      expect(city.getName('en'), equals('Fifth Settlement'));
    });

    test('District getName should return Arabic or English name based on locale', () {
      const district = District(
        id: 1051,
        cityId: 105,
        nameAr: 'الحي الأول',
        nameEn: 'First District',
      );

      expect(district.getName('ar'), equals('الحي الأول'));
      expect(district.getName('en'), equals('First District'));
    });
  });
}
