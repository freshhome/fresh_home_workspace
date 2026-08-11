import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/data/user/datasources/address_remote_datasource.dart';
import 'package:shared/data/user/datasources/geographic_reference_remote_datasource.dart';
import 'package:shared/data/user/datasources/user_local_datasource.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared/data/user/repositories/address_repository_impl.dart';
import 'package:shared/data/user/repositories/geographic_reference_repository_impl.dart';
import 'package:shared/data/user/repositories/user_repository_impl.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';
import 'package:shared/domain/user/repositories/geographic_reference_repository.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/domain/user/usecases/create_address_usecase.dart';
import 'package:shared/domain/user/usecases/delete_address_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_cities_by_governorate_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_districts_by_city_usecase.dart';
import 'package:shared/domain/user/usecases/get_active_governorates_usecase.dart';
import 'package:shared/domain/user/usecases/get_user_addresses_usecase.dart';
import 'package:shared/domain/user/usecases/set_primary_address_usecase.dart';
import 'package:shared/domain/user/usecases/update_address_usecase.dart';
import 'package:shared/domain/user/use_cases/user/create_user_use_case.dart';
import 'package:shared/domain/user/use_cases/user/get_user_by_id_use_case.dart';
import 'package:shared/domain/user/use_cases/user/update_user_use_case.dart';
import 'package:shared/presentation/location/cubit/geographic_reference_cubit.dart';

void setupUserDI(GetIt getIt) {
  // Data sources
  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(),
  );

  getIt.registerLazySingleton<AddressRemoteDataSource>(
    () => AddressRemoteDataSourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<GeographicReferenceRemoteDataSource>(
    () => GeographicReferenceRemoteDataSourceImpl(supabaseClient: getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: getIt<UserRemoteDataSource>(),
      localDataSource: getIt<UserLocalDataSource>(),
    ),
  );

  getIt.registerLazySingleton<AddressRepository>(
    () => AddressRepositoryImpl(
      remoteDataSource: getIt<AddressRemoteDataSource>(),
    ),
  );

  getIt.registerLazySingleton<GeographicReferenceRepository>(
    () => GeographicReferenceRepositoryImpl(
      remoteDataSource: getIt<GeographicReferenceRemoteDataSource>(),
    ),
  );

  // User Use cases
  getIt.registerLazySingleton<CreateUserUseCase>(
    () => CreateUserUseCase(
      userRepository: getIt<UserRepository>(),
    ),
  );

  getIt.registerLazySingleton<GetUserByIdUseCase>(
    () => GetUserByIdUseCase(userRepository: getIt<UserRepository>()),
  );

  getIt.registerLazySingleton<UpdateUserUseCase>(
    () => UpdateUserUseCase(userRepository: getIt<UserRepository>()),
  );

  // Address System V2 Use cases
  getIt.registerLazySingleton<GetUserAddressesUseCase>(
    () => GetUserAddressesUseCase(getIt<AddressRepository>()),
  );

  getIt.registerLazySingleton<CreateAddressUseCase>(
    () => CreateAddressUseCase(getIt<AddressRepository>()),
  );

  getIt.registerLazySingleton<UpdateAddressUseCase>(
    () => UpdateAddressUseCase(getIt<AddressRepository>()),
  );

  getIt.registerLazySingleton<DeleteAddressUseCase>(
    () => DeleteAddressUseCase(getIt<AddressRepository>()),
  );

  getIt.registerLazySingleton<SetPrimaryAddressUseCase>(
    () => SetPrimaryAddressUseCase(getIt<AddressRepository>()),
  );

  // Geographic Reference System Use Cases
  getIt.registerLazySingleton<GetActiveGovernoratesUseCase>(
    () => GetActiveGovernoratesUseCase(getIt<GeographicReferenceRepository>()),
  );

  getIt.registerLazySingleton<GetActiveCitiesByGovernorateUseCase>(
    () => GetActiveCitiesByGovernorateUseCase(getIt<GeographicReferenceRepository>()),
  );

  getIt.registerLazySingleton<GetActiveDistrictsByCityUseCase>(
    () => GetActiveDistrictsByCityUseCase(getIt<GeographicReferenceRepository>()),
  );

  // Geographic Reference State Management Cubit
  getIt.registerFactory<GeographicReferenceCubit>(
    () => GeographicReferenceCubit(
      getActiveGovernoratesUseCase: getIt<GetActiveGovernoratesUseCase>(),
      getActiveCitiesByGovernorateUseCase: getIt<GetActiveCitiesByGovernorateUseCase>(),
      getActiveDistrictsByCityUseCase: getIt<GetActiveDistrictsByCityUseCase>(),
    ),
  );
}
