import 'package:flutter_test/flutter_test.dart';
import 'package:shared/data/technician/models/smart_schedule_model.dart';
import 'package:shared/domain/technician/entities/smart_schedule_entry.dart';

void main() {
  group('SmartScheduleModel', () {
    final tDate = DateTime(2026, 4, 21);
    final tJson = {
      'target_date': tDate.toIso8601String(),
      'suggested_status': 'recommended',
      'utilization_percentage': 0.6,
      'current_load': 6,
      'effective_capacity': 10,
      'risk_score': 0.2,
      'force_multiplier': 1.0,
      'suggestion': 'Good day',
      'is_override': false,
    };

    test('should be a subclass of SmartScheduleEntry', () async {
      // arrange
      final model = SmartScheduleModel.fromJson(tJson);
      // assert
      expect(model, isA<SmartScheduleEntry>());
    });

    test('fromJson should return a valid model', () async {
      // act
      final result = SmartScheduleModel.fromJson(tJson);
      // assert
      expect(result.status, 'recommended');
      expect(result.capacity, 10);
      expect(result.bookingsCount, 6);
      expect(result.utilization, 0.6);
    });

    test('toEntity should return a valid entity', () async {
      // arrange
      final model = SmartScheduleModel.fromJson(tJson);
      // act
      final result = model.toEntity();
      // assert
      expect(result, isA<SmartScheduleEntry>());
      expect(result.status, model.status);
    });
  });
}
