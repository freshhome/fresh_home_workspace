import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';

Future<void> initBookingFlowDI(GetIt getIt) async {
  getIt.registerFactoryParam<BookingFlowCubit, BookingCubitParams, void>(
    (params, _) {
      final config = params.config;
      return BookingFlowCubit(
        config: config,
        calculatePriceUseCase: getIt<CalculatePriceUseCase>(),
        createBookingUseCase: getIt<CreateBookingUseCase>(),
        getAvailableDaysUseCase: getIt<GetAvailableDaysUseCase>(),
        checkActiveCouponsUseCase: getIt<CheckActiveCouponsUseCase>(),
        // Profile sync only in customer mode
        profileRepository:
            config.requiresProfileSync ? getIt<ProfileRepository>() : null,
        // Service loading only in admin mode
        serviceRepository:
            config.requiresServiceSelection ? getIt<ServiceRepository>() : null,
      );
    },
  );
}
