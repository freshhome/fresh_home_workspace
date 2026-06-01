import 'package:get_it/get_it.dart';
import '../data/data_sources/user_management_remote_data_source.dart';
import '../data/repositories_impl/user_management_repository_impl.dart';
import '../domain/repositories/user_management_repository.dart';
import '../presentation/cubit/user_management_cubit.dart';
import '../presentation/cubit/user_detail_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final sl = GetIt.instance;

Future<void> initUserManagementDI() async {
  // Data sources
  sl.registerLazySingleton<UserManagementRemoteDataSource>(
    () => UserManagementRemoteDataSourceImpl(sl<SupabaseClient>()),
  );

  // Repository
  sl.registerLazySingleton<UserManagementRepository>(
    () => UserManagementRepositoryImpl(sl<UserManagementRemoteDataSource>()),
  );

  // Cubits
  sl.registerFactory(() => UserManagementCubit(sl<UserManagementRepository>()));
  sl.registerFactory(() => UserDetailCubit(sl<UserManagementRepository>()));
}
