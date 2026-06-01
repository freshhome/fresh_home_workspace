import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/data/booking/datasources/booking_local_datasource.dart';
import 'package:shared/data/booking/datasources/booking_remote_datasource.dart';
import 'package:shared/data/booking/repositories/booking_repository_impl.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/domain/booking/use_cases/booking/create_booking_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/update_booking_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/calculate_price_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/get_booking_by_id_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/get_user_bookings_use_case.dart';
import 'package:shared/data/booking/datasources/availability_remote_datasource.dart';
import 'package:shared/data/booking/repositories/availability_repository_impl.dart';
import 'package:shared/domain/booking/repositories/availability_repository.dart';
import 'package:shared/domain/booking/use_cases/booking/get_available_days_use_case.dart';

import 'package:shared/data/booking/datasources/admin_booking_remote_data_source.dart';
import 'package:shared/data/booking/repositories/admin_booking_repository_impl.dart';
import 'package:shared/domain/booking/repositories/admin_booking_repository.dart';
import 'package:shared/domain/booking/usecases/admin_cancel_booking_use_case.dart';
import 'package:shared/domain/booking/usecases/admin_reassign_booking_use_case.dart';
import 'package:shared/domain/booking/usecases/admin_reschedule_booking_use_case.dart';

void setupBookingDI(GetIt getIt) {
  // Data sources
  getIt.registerLazySingleton<BookingRemoteDataSource>(
    () => BookingRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<BookingLocalDataSource>(
    () => BookingLocalDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<BookingRepository>(
    () => BookingRepositoryImpl(
      remoteDataSource: getIt<BookingRemoteDataSource>(),
      localDataSource: getIt<BookingLocalDataSource>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<CreateBookingUseCase>(
    () => CreateBookingUseCase(repository: getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<UpdateBookingUseCase>(
    () => UpdateBookingUseCase(repository: getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<CalculatePriceUseCase>(
    () => CalculatePriceUseCase(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<GetBookingByIdUseCase>(
    () => GetBookingByIdUseCase(repository: getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<GetUserBookingsUseCase>(
    () => GetUserBookingsUseCase(repository: getIt<BookingRepository>()),
  );

  // Availability
  getIt.registerLazySingleton<AvailabilityRemoteDataSource>(
    () => AvailabilityRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<AvailabilityRepository>(
    () => AvailabilityRepositoryImpl(
      remoteDataSource: getIt<AvailabilityRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<GetAvailableDaysUseCase>(
    () => GetAvailableDaysUseCase(repository: getIt<AvailabilityRepository>()),
  );

  // Admin Booking
  getIt.registerLazySingleton<AdminBookingRemoteDataSource>(
    () => AdminBookingRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<AdminBookingRepository>(
    () => AdminBookingRepositoryImpl(getIt<AdminBookingRemoteDataSource>()),
  );

  getIt.registerLazySingleton<AdminReassignBookingUseCase>(
    () => AdminReassignBookingUseCase(getIt<AdminBookingRepository>()),
  );

  getIt.registerLazySingleton<AdminCancelBookingUseCase>(
    () => AdminCancelBookingUseCase(getIt<AdminBookingRepository>()),
  );

  getIt.registerLazySingleton<AdminRescheduleBookingUseCase>(
    () => AdminRescheduleBookingUseCase(getIt<AdminBookingRepository>()),
  );
}
