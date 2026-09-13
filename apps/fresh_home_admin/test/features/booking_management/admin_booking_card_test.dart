import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:fresh_home_admin/features/booking_management/presentation/widgets/admin_booking_card.dart';

void main() {
  final sampleBooking = Booking(
    id: 'bk-123',
    userId: 'usr-456',
    technicianId: 'tech-789',
    serviceId: 'srv-1',
    readableId: 'FH-9876',
    service: const BookedService(
      id: 'bs-1',
      subServiceId: 'sub-clean',
      name: {'ar': 'تنظيف عميق', 'en': 'Deep Cleaning'},
      image: '',
    ),
    address: Address(
      id: 'addr-1',
      userId: 'usr-456',
      governorate: 'القاهرة',
      city: 'مدينة نصر',
      district: 'الحي الأول',
      streetOrCompound: 'شارع 90',
      buildingIdentifier: '10',
      createdAt: DateTime(2026, 9, 1),
      updatedAt: DateTime(2026, 9, 1),
    ),
    price: const BookingPricing(
      basePrice: 250,
      extraFees: 0,
      discount: 0,
      total: 250,
    ),
    status: OrderStatus.accepted,
    scheduledAt: DateTime(2026, 9, 15, 10, 30),
    startTimeSlot: '10:30',
    contact: const Contact(
      name: 'أحمد محمود',
      phone: ['01012345678'],
    ),
    createdAt: DateTime(2026, 9, 1),
    updatedAt: DateTime(2026, 9, 1),
    isWhatsappConfirmed: true,
    isCritical: false,
  );

  Widget createWidgetUnderTest(Booking booking) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AdminBookingCard(booking: booking),
          ),
        ),
      ),
    );
  }

  group('AdminBookingCard Design & Quick Actions Tests', () {
    testWidgets('1. Upper half renders service name, ID badge, district and formatted price', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleBooking));
      await tester.pumpAndSettle();

      // Row 1: Service Name & ID
      expect(find.text('تنظيف عميق'), findsOneWidget);
      expect(find.text('#FH-9876'), findsOneWidget);

      // Row 2: District & Price
      expect(find.text('الحي الأول'), findsOneWidget);
      expect(find.textContaining('السعر :'), findsOneWidget);
      expect(find.textContaining('250'), findsOneWidget);
      expect(find.textContaining('ج.م'), findsOneWidget);
    });

    testWidgets('2. Lower half renders all 5 square action icon buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleBooking));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin_card_call_button')), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);

      expect(find.byKey(const Key('admin_card_reschedule_button')), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);

      expect(find.byKey(const Key('admin_card_technician_button')), findsOneWidget);
      expect(find.byIcon(Icons.manage_accounts_outlined), findsOneWidget);

      expect(find.byKey(const Key('admin_card_cancel_button')), findsOneWidget);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);

      expect(find.byKey(const Key('admin_card_delete_button')), findsOneWidget);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });

    testWidgets('3. Tapping delete icon button opens permanent delete confirmation dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleBooking));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_card_delete_button')));
      await tester.pumpAndSettle();

      expect(find.text('تأكيد الحذف النهائي'), findsOneWidget);
      expect(find.text('هل أنت متأكد من رغبتك في حذف الحجز رقم #FH-9876 نهائياً؟'), findsOneWidget);
      expect(find.text('إلغاء'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد الحذف النهائي'), findsNothing);
    });

    testWidgets('4. Tapping cancel icon button opens cancellation reason dialog', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleBooking));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_card_cancel_button')));
      await tester.pumpAndSettle();

      expect(find.text('هل أنت متأكد من إلغاء الحجز رقم #FH-9876؟'), findsOneWidget);
      expect(find.text('سبب الإلغاء:'), findsOneWidget);
      expect(find.text('تراجع'), findsOneWidget);
      expect(find.text('تأكيد الإلغاء'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('تراجع'));
      await tester.pumpAndSettle();
      expect(find.text('تأكيد الإلغاء'), findsNothing);
    });

    testWidgets('5. Tapping reschedule icon button opens reschedule bottom sheet', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(sampleBooking));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('admin_card_reschedule_button')));
      await tester.pumpAndSettle();

      expect(find.text('تعديل موعد الحجز'), findsOneWidget);
      expect(find.text('التاريخ الجديد:'), findsOneWidget);
      expect(find.text('الوقت الجديد:'), findsOneWidget);
      expect(find.text('تأكيد تعديل الموعد'), findsOneWidget);
    });

    testWidgets('6. Completed booking renders only 3 buttons (Call, Re-book, Delete) and hides reschedule, tech, cancel', (tester) async {
      final completedBooking = sampleBooking.copyWith(status: OrderStatus.completed);
      await tester.pumpWidget(createWidgetUnderTest(completedBooking));
      await tester.pumpAndSettle();

      // Renders Call, Re-book, Delete
      expect(find.byKey(const Key('admin_card_call_button')), findsOneWidget);
      expect(find.byKey(const Key('admin_card_rebook_button')), findsOneWidget);
      expect(find.byKey(const Key('admin_card_delete_button')), findsOneWidget);

      // Does NOT render Reschedule, Technician, Cancel
      expect(find.byKey(const Key('admin_card_reschedule_button')), findsNothing);
      expect(find.byKey(const Key('admin_card_technician_button')), findsNothing);
      expect(find.byKey(const Key('admin_card_cancel_button')), findsNothing);
    });
  });
}
