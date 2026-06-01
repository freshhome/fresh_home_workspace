import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_features/shared_features.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/domain/booking/use_cases/booking/transition_booking_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/update_booking_schedule_use_case.dart';
import 'package:shared/domain/booking/use_cases/booking/update_booking_address_use_case.dart';

import '../domain/use_cases/get_my_orders.dart';
import '../presentation/cubit/my_orders_cubit.dart';
import '../presentation/cubit/edit_order_cubit.dart';

Future<void> initMyOrdersDI(GetIt getIt) async {
  // Use Cases
  getIt.registerLazySingleton<GetMyOrders>(
    () => GetMyOrders(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<TransitionBookingUseCase>(
    () => TransitionBookingUseCase(repository: getIt<BookingRepository>()),
  );
  
  getIt.registerLazySingleton<UpdateBookingScheduleUseCase>(
    () => UpdateBookingScheduleUseCase(getIt<BookingRepository>()),
  );

  getIt.registerLazySingleton<UpdateBookingAddressUseCase>(
    () => UpdateBookingAddressUseCase(getIt<BookingRepository>()),
  );

  // Cubits
  getIt.registerFactory<MyOrdersCubit>(
    () => MyOrdersCubit(
      getMyOrders: getIt<GetMyOrders>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );

  getIt.registerFactory<EditOrderCubit>(
    () => EditOrderCubit(
      supabase: getIt<SupabaseClient>(),
      profileRepository: getIt<ProfileRepository>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      transitionBooking: getIt<TransitionBookingUseCase>(),
      updateBookingScheduleUseCase: getIt<UpdateBookingScheduleUseCase>(),
      updateBookingAddressUseCase: getIt<UpdateBookingAddressUseCase>(),
    ),
  );
}
