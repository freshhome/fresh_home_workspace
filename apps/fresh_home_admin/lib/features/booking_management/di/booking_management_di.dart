import 'package:get_it/get_it.dart';

import '../domain/usecases/admin_watch_bookings.dart';
import '../domain/usecases/admin_reassign_booking.dart';
import '../domain/usecases/admin_reschedule_booking.dart';
import '../domain/usecases/admin_delete_booking.dart';
import '../presentation/cubit/admin_bookings_cubit.dart';
import '../presentation/cubit/admin_booking_details_cubit.dart';
import '../presentation/cubit/admin_booking_drafts_cubit.dart';

Future<void> initBookingManagementDI(GetIt getIt) async {
  // Data Sources and Repositories are now provided by the shared package via initSharedDI()

  // Use Cases
  getIt.registerLazySingleton(() => AdminWatchBookings(getIt()));
  getIt.registerLazySingleton(() => AdminReassignBooking(getIt()));
  getIt.registerLazySingleton(() => AdminRescheduleBooking(getIt()));
  getIt.registerLazySingleton(() => AdminDeleteBooking(getIt()));

  // Cubits
  getIt.registerFactory(
    () => AdminBookingsCubit(getIt()),
  );

    getIt.registerFactory(
    () => AdminBookingDetailsCubit(
      watchBookings: getIt(),
      reassignBooking: getIt(),
      rescheduleBooking: getIt(),
      userRepository: getIt(),
      bookingRepository: getIt(),
    ),
  );

  getIt.registerFactory(
    () => AdminBookingDraftsCubit(repository: getIt()),
  );
}
