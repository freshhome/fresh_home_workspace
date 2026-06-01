import 'package:fresh_home_admin/features/admin_dashboard/data/datasources/admin_dashboard_remote_datasource.dart';
import 'package:fresh_home_admin/features/admin_dashboard/data/repositories/admin_dashboard_repository_impl.dart';
import 'package:fresh_home_admin/features/admin_dashboard/domain/repositories/admin_dashboard_repository.dart';
import 'package:fresh_home_admin/features/admin_dashboard/presentation/cubit/admin_dashboard_cubit.dart';
import 'package:get_it/get_it.dart';


void setupAdminDashboardDI(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<AdminDashboardRemoteDataSource>(
    () => AdminDashboardRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<AdminDashboardRepository>(
    () => AdminDashboardRepositoryImpl(sl()),
  );

  // Cubit
  sl.registerFactory<AdminDashboardCubit>(
    () => AdminDashboardCubit(sl()),
  );
}
