import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/booking/entities/booking/booking_draft.dart';

void main() {
  group('BookingDraft Entity and Serialization Test', () {
    final now = DateTime(2026, 9, 3, 10, 30);
    final draft = BookingDraft(
      id: 'draft-123',
      createdAt: now,
      updatedAt: now,
      currentStepIndex: 3,
      clientName: 'أحمد محمود',
      clientPhone: '01012345678',
      serviceName: 'تنظيف منازل',
      serviceTitle: const {'ar': 'تنظيف منازل', 'en': 'Home Cleaning'},
      subServiceId: 'sub-service-456',
      priceTotal: 1250.0,
      area: 120.0,
      scheduledAt: now.add(const Duration(days: 1)),
      manualClientGovernorate: 'القاهرة',
      manualClientCity: 'المعادي',
      manualClientAddressDetails: 'شارع 9، عمارة 15',
    );

    test('should convert BookingDraft toMap and fromMap correctly', () {
      final map = draft.toMap();
      final fromMapDraft = BookingDraft.fromMap(map);

      expect(fromMapDraft.id, equals('draft-123'));
      expect(fromMapDraft.clientName, equals('أحمد محمود'));
      expect(fromMapDraft.clientPhone, equals('01012345678'));
      expect(fromMapDraft.serviceName, equals('تنظيف منازل'));
      expect(fromMapDraft.serviceTitle?['ar'], equals('تنظيف منازل'));
      expect(fromMapDraft.priceTotal, equals(1250.0));
      expect(fromMapDraft.manualClientGovernorate, equals('القاهرة'));
      expect(fromMapDraft.manualClientCity, equals('المعادي'));
      expect(fromMapDraft.manualClientAddressDetails, equals('شارع 9، عمارة 15'));
      expect(fromMapDraft.currentStepIndex, equals(3));
    });

    test('should serialize to JSON and deserialize back correctly', () {
      final jsonStr = draft.toJson();
      final fromJsonDraft = BookingDraft.fromJson(jsonStr);

      expect(fromJsonDraft.id, equals(draft.id));
      expect(fromJsonDraft.clientName, equals(draft.clientName));
      expect(fromJsonDraft.clientPhone, equals(draft.clientPhone));
      expect(fromJsonDraft.priceTotal, equals(draft.priceTotal));
      expect(fromJsonDraft.subServiceId, equals(draft.subServiceId));
    });

    test('should support copyWith for updating client address when received on WhatsApp', () {
      final updatedDraft = draft.copyWith(
        manualClientLocationUrl: 'https://maps.google.com/?q=30.0,31.0',
        manualClientAddressDetails: 'شارع 9، عمارة 15، دور 4، شقة 402',
      );

      expect(updatedDraft.id, equals(draft.id));
      expect(updatedDraft.clientName, equals('أحمد محمود'));
      expect(updatedDraft.manualClientLocationUrl, equals('https://maps.google.com/?q=30.0,31.0'));
      expect(updatedDraft.manualClientAddressDetails, equals('شارع 9، عمارة 15، دور 4، شقة 402'));
    });
  });
}
