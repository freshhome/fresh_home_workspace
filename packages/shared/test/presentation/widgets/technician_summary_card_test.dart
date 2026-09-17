import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/presentation/widgets/address_v2/technician_summary_card.dart';

void main() {
  final now = DateTime.now();

  Address createAddress({
    double? latitude,
    double? longitude,
    String? locationUrl,
  }) {
    return Address(
      id: 'addr-1',
      userId: 'usr-1',
      governorate: 'القاهرة',
      city: 'القاهرة الجديدة',
      district: 'التجمع الخامس',
      addressDetails: 'شارع التسعين، مبنى 10',
      latitude: latitude,
      longitude: longitude,
      locationUrl: locationUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  Widget createWidgetUnderTest(Address address, {VoidCallback? onOpenMaps}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TechnicianSummaryCard(
            address: address,
            customerName: 'أحمد محمود',
            customerPhone: '01012345678',
            onOpenMaps: onOpenMaps,
          ),
        ),
      ),
    );
  }

  group('TechnicianSummaryCard Navigation Button Visibility Tests', () {
    testWidgets('1. Hides "بدء الملاحة" button when customer has no location registered', (tester) async {
      final addressWithoutLocation = createAddress(latitude: null, longitude: null, locationUrl: null);
      bool mapTapped = false;

      await tester.pumpWidget(createWidgetUnderTest(
        addressWithoutLocation,
        onOpenMaps: () => mapTapped = true,
      ));
      await tester.pumpAndSettle();

      // Navigation button must NOT be present
      expect(find.text('بدء الملاحة'), findsNothing);
      expect(find.text('فتح في Google Maps'), findsNothing);
      expect(mapTapped, isFalse);
    });

    testWidgets('2. Shows "بدء الملاحة" button when customer registered GPS coordinates', (tester) async {
      final addressWithGps = createAddress(latitude: 30.0444, longitude: 31.2357);
      bool mapTapped = false;

      await tester.pumpWidget(createWidgetUnderTest(
        addressWithGps,
        onOpenMaps: () => mapTapped = true,
      ));
      await tester.pumpAndSettle();

      // Navigation button MUST be present
      expect(find.text('بدء الملاحة'), findsOneWidget);
      expect(find.text('فتح في Google Maps'), findsOneWidget);

      await tester.tap(find.text('بدء الملاحة'));
      expect(mapTapped, isTrue);
    });

    testWidgets('3. Shows "بدء الملاحة" button when customer registered locationUrl link', (tester) async {
      final addressWithUrl = createAddress(locationUrl: 'https://maps.google.com/?q=30.0,31.0');
      bool mapTapped = false;

      await tester.pumpWidget(createWidgetUnderTest(
        addressWithUrl,
        onOpenMaps: () => mapTapped = true,
      ));
      await tester.pumpAndSettle();

      // Navigation button MUST be present
      expect(find.text('بدء الملاحة'), findsOneWidget);
      expect(find.text('فتح في Google Maps'), findsOneWidget);

      await tester.tap(find.text('بدء الملاحة'));
      expect(mapTapped, isTrue);
    });
  });
}
