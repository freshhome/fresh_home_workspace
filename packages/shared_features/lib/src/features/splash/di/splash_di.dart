import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/domain/service/use_cases/service/sync_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/start_realtime_sync_use_case.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/verify_role.dart';
import 'package:shared_features/src/features/onboarding/domain/use_cases/is_onboarding_completed_use_case.dart';
import 'package:shared_features/src/features/splash/data/data_sources/splash_data_sources.dart';
import 'package:shared_features/src/features/splash/data/repositories_impl/splash_repositories_impl.dart';
import 'package:shared_features/src/features/splash/domain/repositories/splash_repositories.dart';
import 'package:shared_features/src/features/splash/domain/use_cases/is_user_logged_in_use_case.dart';
import 'package:shared_features/src/features/splash/presentation/cubit/splash_cubit.dart';

Future<void> initSplashDI(GetIt getIt, {required UserRole appRole}) async {
  // Data sources
  getIt.registerLazySingleton<SplashDataSources>(
    () => SplashDataSourcesImpl(getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<SplashRepositories>(
    () => SplashRepositoriesImpl(splashDataSources: getIt<SplashDataSources>()),
  );

  // Use cases
  getIt.registerLazySingleton<IsUserLoggedInUseCase>(
    () => IsUserLoggedInUseCase(getIt<SplashRepositories>()),
  );

  // Cubit
  getIt.registerLazySingleton<SplashCubit>(
    () => SplashCubit(
      getIt<IsUserLoggedInUseCase>(),
      getIt<IsOnboardingCompletedUseCase>(),
      getIt<SyncServicesUseCase>(),
      getIt<StartRealtimeSyncUseCase>(),
      getIt<VerifyRoleUseCase>(),
      appRole,
    ),
  );
}
