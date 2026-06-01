import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../cubit/admin_bookings_cubit.dart';
import '../cubit/admin_booking_details_cubit.dart';
import '../pages/admin_booking_list_screen.dart';
import '../pages/admin_booking_details_screen.dart';
import '../../../../core/di/injection_container.dart';

class BookingManagementRoutes {
  static const String bookingListPath = '/admin/bookings';
  static const String bookingDetailPath = '/admin/bookings/detail';

  static final routes = [
    GoRoute(
      path: bookingListPath,
      name: 'adminBookings',
      builder: (context, state) => BlocProvider(
        create: (context) => getIt<AdminBookingsCubit>(),
        child: const AdminBookingListScreen(),
      ),
      routes: [
        GoRoute(
          path: 'detail/:id',
          name: AppRoutes.orderDetails,
          builder: (context, state) {
            final booking = state.extra as Booking?;
            final bookingId = state.pathParameters['id'] ?? state.uri.queryParameters['id'];
            
            return BlocProvider(
              create: (context) => getIt<AdminBookingDetailsCubit>(),
              child: AdminBookingDetailsScreen(
                booking: booking,
                bookingId: bookingId,
              ),
            );
          },
        ),
      ],
    ),
  ];
}
