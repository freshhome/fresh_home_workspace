import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared/shared.dart';
import 'package:shared/domain/booking/repositories/booking_draft_repository.dart';
import 'package:fresh_home_admin/features/booking_management/presentation/cubit/admin_bookings_cubit.dart';
import 'package:fresh_home_admin/features/booking_management/presentation/cubit/admin_booking_drafts_cubit.dart';
import 'package:fresh_home_admin/features/booking_management/presentation/pages/admin_booking_list_screen.dart';

class FakeAdminBookingsCubit extends Cubit<AdminBookingsState>
    implements AdminBookingsCubit {
  FakeAdminBookingsCubit(super.initialState);

  @override
  Future<void> refreshBookings() async {}
}

class FakeBookingDraftRepository implements BookingDraftRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAdminBookingDraftsCubit extends Cubit<AdminBookingDraftsState>
    implements AdminBookingDraftsCubit {
  FakeAdminBookingDraftsCubit() : super(const AdminBookingDraftsLoaded([]));

  @override
  BookingDraftRepository get repository => FakeBookingDraftRepository();

  @override
  Future<void> loadDrafts() async {}

  @override
  Future<void> deleteDraft(String draftId) async {}

  @override
  Future<void> clearAllDrafts() async {}
}

void main() {
  final now = DateTime.now();
  final sampleTodayBooking = Booking(
    id: 'bk-today',
    userId: 'usr-1',
    serviceId: 'srv-1',
    readableId: 'FH-TODAY',
    service: const BookedService(
      id: 'bs-1',
      subServiceId: 'sub-clean',
      name: {'ar': 'تنظيف اليوم'},
      image: '',
    ),
    address: Address(
      id: 'addr-1',
      userId: 'usr-1',
      governorate: 'القاهرة',
      city: 'التجمع',
      district: 'الحي الأول',
      streetOrCompound: 'شارع التسعين',
      buildingIdentifier: '1',
      createdAt: now,
      updatedAt: now,
    ),
    price: const BookingPricing(basePrice: 500, extraFees: 0, discount: 0, total: 500),
    status: OrderStatus.accepted,
    scheduledAt: now,
    startTimeSlot: '12:00',
    contact: const Contact(name: 'عميل اليوم', phone: ['01011111111']),
    createdAt: now,
    updatedAt: now,
  );

  final tomorrow = now.add(const Duration(days: 1));
  final sampleTomorrowBooking = Booking(
    id: 'bk-tomorrow',
    userId: 'usr-2',
    serviceId: 'srv-2',
    readableId: 'FH-TOMORROW',
    service: const BookedService(
      id: 'bs-2',
      subServiceId: 'sub-clean',
      name: {'ar': 'تنظيف غداً'},
      image: '',
    ),
    address: Address(
      id: 'addr-2',
      userId: 'usr-2',
      governorate: 'القاهرة',
      city: 'المعادي',
      district: 'دجلة',
      streetOrCompound: 'شارع النصر',
      buildingIdentifier: '1',
      createdAt: now,
      updatedAt: now,
    ),
    price: const BookingPricing(basePrice: 700, extraFees: 0, discount: 0, total: 700),
    status: OrderStatus.accepted,
    scheduledAt: tomorrow,
    startTimeSlot: '14:00',
    contact: const Contact(name: 'عميل غداً', phone: ['01022222222']),
    createdAt: now,
    updatedAt: now,
  );

  Widget createWidgetUnderTest(AdminBookingsCubit bookingsCubit) {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AdminBookingsCubit>.value(value: bookingsCubit),
          BlocProvider<AdminBookingDraftsCubit>.value(
            value: FakeAdminBookingDraftsCubit(),
          ),
        ],
        child: const AdminBookingListScreen(),
      ),
    );
  }

  testWidgets('Renders 6 tabs in exact order: اليوم, غداً, طارئ, الكل, المكتملة, الملغاة', (tester) async {
    final bookingsCubit = FakeAdminBookingsCubit(
      AdminBookingsLoaded(
        allBookings: [sampleTodayBooking, sampleTomorrowBooking],
        activeBookings: [sampleTodayBooking, sampleTomorrowBooking],
        completedBookings: [],
        cancelledBookings: [],
      ),
    );

    await tester.pumpWidget(createWidgetUnderTest(bookingsCubit));
    await tester.pumpAndSettle();

    // Verify all 6 tabs exist
    expect(find.text('اليوم'), findsOneWidget);
    expect(find.text('غداً'), findsOneWidget);
    expect(find.text('طارئ'), findsOneWidget);
    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('المكتملة'), findsOneWidget);
    expect(find.text('الملغاة'), findsOneWidget);

    // TabBar has 6 tabs
    final tabBar = tester.widget<TabBar>(find.byType(TabBar));
    expect(tabBar.tabs.length, 6);

    // Today booking is rendered in the first active tab (اليوم)
    expect(find.text('تنظيف اليوم'), findsOneWidget);
  });
}
