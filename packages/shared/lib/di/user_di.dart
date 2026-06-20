import 'package:get_it/get_it.dart';
import 'package:shared/data/user/datasources/user_local_datasource.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared/data/user/repositories/user_repository_impl.dart';
import 'package:shared/domain/counter/use_cases/generate_next_id_usecase/get_next_id_use_case.dart';
import 'package:shared/domain/user/repositories/user_repository.dart';
import 'package:shared/domain/user/use_cases/user/create_user_use_case.dart';
import 'package:shared/domain/user/use_cases/user/get_user_by_id_use_case.dart';
import 'package:shared/domain/user/use_cases/user/update_user_use_case.dart';

void setupUserDI(GetIt getIt) {
  // Data sources
  getIt.registerLazySingleton<UserLocalDataSource>(
    () => UserLocalDataSourceImpl(),
  );

  // Repository
  getIt.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      remoteDataSource: getIt<UserRemoteDataSource>(),
      localDataSource: getIt<UserLocalDataSource>(),
    ),
  );
  // Use cases
  // CreateUserUseCase
  getIt.registerLazySingleton<CreateUserUseCase>(
    () => CreateUserUseCase(
      userRepository: getIt<UserRepository>(),
    ),
  );

  // GetUserByIdUseCase
  getIt.registerLazySingleton<GetUserByIdUseCase>(
    () => GetUserByIdUseCase(userRepository: getIt<UserRepository>()),
  );

  // UpdateUserUseCase
  getIt.registerLazySingleton<UpdateUserUseCase>(
    () => UpdateUserUseCase(userRepository: getIt<UserRepository>()),
  );
}
