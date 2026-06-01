import 'package:get_it/get_it.dart';
import 'package:shared/data/counter/datasources/counter_remote_data_source.dart';
import 'package:shared/data/counter/repositories/counter_repository_impl.dart';
import 'package:shared/domain/counter/repositories/counter_repository.dart';
import 'package:shared/domain/counter/use_cases/generate_next_id_usecase/get_next_id_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void setupCounterDI(GetIt getIt) {
  // Data sources
  getIt.registerLazySingleton<CounterRemoteDataSource>(
    () => CounterRemoteDataSourceImpl(supabase: getIt<SupabaseClient>()),
  );

  // Repository
  getIt.registerLazySingleton<CounterRepository>(
    () => CounterRepositoryImpl(remoteDataSource: getIt()),
  );

  // Use cases
  getIt.registerLazySingleton<GetNextIdUseCase>(
    () => GetNextIdUseCase(getIt()),
  );
}
