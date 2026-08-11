import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/user/models/city_model.dart';
import 'package:shared/data/user/models/district_model.dart';
import 'package:shared/data/user/models/governorate_model.dart';

void main() {
  group('Geographic Reference Models JSON & Entity Unit Tests', () {
    test('GovernorateModel JSON serialization & toEntity mapping', () {
      final json = {
        'id': 1,
        'name_ar': 'القاهرة',
        'name_en': 'Cairo',
        'code': 'CAI',
        'is_active': true,
        'sort_order': 1,
      };

      final model = GovernorateModel.fromJson(json);
      expect(model.id, equals(1));
      expect(model.nameAr, equals('القاهرة'));
      expect(model.nameEn, equals('Cairo'));

      final entity = model.toEntity();
      expect(entity.id, equals(1));
      expect(entity.getName('ar'), equals('القاهرة'));
      expect(entity.getName('en'), equals('Cairo'));
    });

    test('CityModel JSON serialization & toEntity mapping', () {
      final json = {
        'id': 105,
        'governorate_id': 1,
        'name_ar': 'التجمع الخامس',
        'name_en': 'Fifth Settlement',
        'is_active': true,
        'sort_order': 5,
      };

      final model = CityModel.fromJson(json);
      expect(model.id, equals(105));
      expect(model.governorateId, equals(1));

      final entity = model.toEntity();
      expect(entity.governorateId, equals(1));
      expect(entity.getName('en'), equals('Fifth Settlement'));
    });

    test('DistrictModel JSON serialization & toEntity mapping', () {
      final json = {
        'id': 1051,
        'city_id': 105,
        'name_ar': 'الحي الأول',
        'name_en': 'First District',
        'is_active': true,
        'sort_order': 1,
      };

      final model = DistrictModel.fromJson(json);
      expect(model.id, equals(1051));
      expect(model.cityId, equals(105));

      final entity = model.toEntity();
      expect(entity.cityId, equals(105));
      expect(entity.getName('ar'), equals('الحي الأول'));
    });
  });
}
