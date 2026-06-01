import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared_features/src/features/authentication/data/authentication_data.dart';
import 'package:shared_features/src/features/profile/data/profile_data.dart';
import 'package:shared_features/src/features/profile/domain/profile_domain.dart';
import 'package:shared_features/src/features/profile/presentation/profile_presentation.dart';

import 'package:shared_features/src/features/profile/data/data_sources/technician_profile_remote_data_source.dart';

Future<void> initProfileDI(GetIt getIt) async {
  // Data Sources
  getIt.registerLazySingleton<ClientProfileRemoteDataSource>(
    () => ClientProfileRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
  getIt.registerLazySingleton<TechnicianProfileRemoteDataSource>(
    () => TechnicianProfileRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      localDataSource: getIt<AuthLocalDataSource>(),
      userRemoteDataSource: getIt<UserRemoteDataSource>(),
      clientProfileRemoteDataSource: getIt<ClientProfileRemoteDataSource>(),
      technicianProfileRemoteDataSource:
          getIt<TechnicianProfileRemoteDataSource>(),
      supabase: getIt<SupabaseClient>(),
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(() => LoadProfileUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateUserNameUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdatePhoneNumbersUseCase(getIt()));
  getIt.registerLazySingleton(() => AddAddressUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateAddressUseCase(getIt()));
  getIt.registerLazySingleton(() => DeleteAddressUseCase(getIt()));
  getIt.registerLazySingleton(() => UpdateProfileUseCase(getIt()));

  // Cubit
  getIt.registerFactory<ProfileCubit>(
    () => ProfileCubit(
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
      getIt(),
    ),
  );
}
