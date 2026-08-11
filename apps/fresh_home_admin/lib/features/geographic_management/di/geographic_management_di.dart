import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/shared.dart';


final sl = GetIt.instance;

void initGeographicManagementDI() {
  // Admin Geographic Reference Repository
  if (!sl.isRegistered<AdminGeographicReferenceRepository>()) {
    sl.registerLazySingleton<AdminGeographicReferenceRepository>(
      () => AdminGeographicReferenceRepositoryImpl(
        supabaseClient: sl<SupabaseClient>(),
        clientRepository: sl.isRegistered<GeographicReferenceRepository>() &&
                sl<GeographicReferenceRepository>() is GeographicReferenceRepositoryImpl
            ? sl<GeographicReferenceRepository>() as GeographicReferenceRepositoryImpl
            : null,
      ),
    );
  }

  // Admin Geographic Reference Cubit
  if (!sl.isRegistered<AdminGeographicReferenceCubit>()) {
    sl.registerFactory<AdminGeographicReferenceCubit>(
      () => AdminGeographicReferenceCubit(
        repository: sl<AdminGeographicReferenceRepository>(),
      ),
    );
  }
}
