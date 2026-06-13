import 'package:get_it/get_it.dart';
import '../data/data_sources/admin_finance_remote_data_source.dart';
import '../data/repositories/admin_finance_repository_impl.dart';
import '../domain/repositories/admin_finance_repository.dart';
import '../presentation/cubit/admin_finance_cubit.dart';
import '../presentation/cubit/admin_reports_cubit.dart';

void initAdminFinanceDI(GetIt sl) {
  // Data Source
  sl.registerLazySingleton<AdminFinanceRemoteDataSource>(
    () => AdminFinanceRemoteDataSourceImpl(sl()),
  );

  // Repository
  sl.registerLazySingleton<AdminFinanceRepository>(
    () => AdminFinanceRepositoryImpl(sl()),
  );

  // Cubits
  sl.registerFactory<AdminFinanceCubit>(
    () => AdminFinanceCubit(sl()),
  );

  sl.registerFactory<AdminReportsCubit>(
    () => AdminReportsCubit(sl()),
  );
}
