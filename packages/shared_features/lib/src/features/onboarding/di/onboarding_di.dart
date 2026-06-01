import 'package:get_it/get_it.dart';
import '../data/datasources/onboarding_local_datasource.dart';
import '../data/repositories/onboarding_repository_impl.dart';
import '../domain/repositories/onboarding_repository.dart';
import '../domain/use_cases/is_onboarding_completed_use_case.dart';
import '../domain/use_cases/set_onboarding_completed_use_case.dart';

import '../presentation/application/cubit/onboarding_cubit.dart';

Future<void> initOnboardingDI(GetIt getIt) async {
  // Data sources
  getIt.registerLazySingleton<OnboardingLocalDataSource>(
    () => OnboardingLocalDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<OnboardingRepository>(
    () => OnboardingRepositoryImpl(getIt<OnboardingLocalDataSource>()),
  );

  // Use cases
  getIt.registerLazySingleton<IsOnboardingCompletedUseCase>(
    () => IsOnboardingCompletedUseCase(getIt<OnboardingRepository>()),
  );
  
  getIt.registerLazySingleton<SetOnboardingCompletedUseCase>(
    () => SetOnboardingCompletedUseCase(getIt<OnboardingRepository>()),
  );

  // Cubit
  getIt.registerFactory<OnboardingCubit>(
    () => OnboardingCubit(getIt<SetOnboardingCompletedUseCase>()),
  );
}
