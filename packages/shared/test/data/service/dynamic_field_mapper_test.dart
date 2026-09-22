import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/service/mappers/service_mapper.dart';
import 'package:shared/data/service/models/remote/sub_models/service_price_remote_model.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/dynamic_field.dart';

void main() {
  group('DynamicFieldEntity - resolveHint', () {
    test('returns specific locale hint when present and non-empty', () {
      const field = DynamicFieldEntity(
        id: 'area',
        type: DynamicFieldType.number,
        label: {'ar': 'المساحة', 'en': 'Area'},
        hint: {
          'ar': 'أدخل المساحة بالمتر المربع',
          'en': 'Enter area in square meters',
        },
      );

      expect(field.resolveHint('ar'), 'أدخل المساحة بالمتر المربع');
      expect(field.resolveHint('en'), 'Enter area in square meters');
    });

    test('falls back to Arabic hint if requested locale hint is missing or empty', () {
      const field = DynamicFieldEntity(
        id: 'area',
        type: DynamicFieldType.number,
        label: {'ar': 'المساحة', 'en': 'Area'},
        hint: {
          'ar': 'أدخل المساحة بالمتر المربع',
          'en': '   ',
        },
      );

      expect(field.resolveHint('en'), 'أدخل المساحة بالمتر المربع');
      expect(field.resolveHint('fr'), 'أدخل المساحة بالمتر المربع');
    });

    test('falls back to localized label if hint is null or completely empty', () {
      const field = DynamicFieldEntity(
        id: 'area',
        type: DynamicFieldType.number,
        label: {'ar': 'المساحة', 'en': 'Area'},
        hint: null,
      );

      expect(field.resolveHint('ar'), 'المساحة');
      expect(field.resolveHint('en'), 'Area');
      expect(field.resolveHint('fr'), 'المساحة');
    });

    test('falls back to Arabic label if localized label is missing', () {
      const field = DynamicFieldEntity(
        id: 'area',
        type: DynamicFieldType.number,
        label: {'ar': 'المساحة'},
        hint: {'ar': '', 'en': ''},
      );

      expect(field.resolveHint('en'), 'المساحة');
    });

    test('falls back to id if both hint and label are empty', () {
      const field = DynamicFieldEntity(
        id: 'area_custom_id',
        type: DynamicFieldType.number,
        label: {},
        hint: null,
      );

      expect(field.resolveHint('ar'), 'area_custom_id');
    });
  });

  group('DynamicFieldRemoteModel - Serialization & Sanitization', () {
    test('serializes hint when non-empty', () {
      const model = DynamicFieldRemoteModel(
        id: 'area',
        type: 'number',
        label: {'ar': 'المساحة'},
        hint: {'ar': '120 م²', 'en': '120 sqm'},
      );

      final json = model.toJson();
      expect(json['hint'], {'ar': '120 م²', 'en': '120 sqm'});
    });

    test('omits hint completely from json if hint is empty or contains only whitespace', () {
      const model = DynamicFieldRemoteModel(
        id: 'area',
        type: 'number',
        label: {'ar': 'المساحة'},
        hint: {'ar': '   ', 'en': ''},
      );

      final json = model.toJson();
      expect(json.containsKey('hint'), isFalse);
    });

    test('parses hint from json correctly', () {
      final json = {
        'id': 'rooms',
        'type': 'number',
        'label': {'ar': 'الغرف'},
        'hint': {'ar': 'عدد الغرف', 'en': 'Room count'},
      };

      final model = DynamicFieldRemoteModel.fromJson(json);
      expect(model.hint, {'ar': 'عدد الغرف', 'en': 'Room count'});
    });
  });

  group('ServiceMapper - DynamicField Mapping with Sanitization', () {
    test('maps model to entity and sanitizes empty strings', () {
      const model = DynamicFieldRemoteModel(
        id: 'area',
        type: 'number',
        label: {'ar': 'المساحة'},
        hint: {'ar': '  تلميح  ', 'en': '   '},
      );

      final entity = ServiceMapper.dynamicFieldRemoteToEntity(model);
      expect(entity.hint, {'ar': 'تلميح'});
    });

    test('maps map to entity and omits empty hint map', () {
      final map = {
        'id': 'area',
        'type': 'number',
        'label': {'ar': 'المساحة'},
        'hint': {'ar': '', 'en': ''},
      };

      final entity = ServiceMapper.dynamicFieldMapToEntity(map);
      expect(entity.hint, isNull);
    });

    test('maps entity to map and omits hint key if null or empty', () {
      const entity = DynamicFieldEntity(
        id: 'area',
        type: DynamicFieldType.number,
        label: {'ar': 'المساحة'},
        hint: {'ar': '   '},
      );

      final map = ServiceMapper.dynamicFieldToMap(entity);
      expect(map.containsKey('hint'), isFalse);
    });
  });
}
