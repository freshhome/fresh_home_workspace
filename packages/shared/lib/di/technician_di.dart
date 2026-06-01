import 'package:get_it/get_it.dart';
import '../data/technician/datasources/technician_remote_datasource.dart';
import '../data/technician/repositories/technician_repository_impl.dart';
import '../domain/technician/repositories/technician_repository.dart';

void setupTechnicianDI(GetIt sl) {
  // Data sources
  sl.registerLazySingleton<TechnicianRemoteDataSource>(
    () => TechnicianRemoteDataSourceImpl(sl()),
  );

  // Repositories
  sl.registerLazySingleton<TechnicianRepository>(
    () => TechnicianRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
}
