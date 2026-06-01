import 'package:get_it/get_it.dart';
import 'package:shared/domain/service/use_cases/service/get_main_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_bookable_services_use_case.dart';
import '../data/home_data.dart';
import '../domain/home_domain.dart';
import '../presentation/home_presentation.dart';

import 'package:fresh_home_customer/features/home/data/sources/supabase_home_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> initHomeDI(GetIt getIt) async {
  // Data Sources
  getIt.registerLazySingleton<HomeRemoteDataSource>(
    () => SupabaseHomeRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(getIt<HomeRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton(
    () => GetHomeDataUseCases(
      getIt(),
      getIt<GetMainServicesUseCase>(),
      getIt<GetBookableServicesUseCase>(),
    ),
  );

  // Cubits
  getIt.registerFactory(() => HomeCubit(getIt()));
}
