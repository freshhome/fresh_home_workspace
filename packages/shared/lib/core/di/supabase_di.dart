import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/data/service/datasources/service_remote_datasource.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';

Future<void> setupSupabaseDI(GetIt getIt) async {
  /// 📦 Supabase Client
  // Note: Replace with your actual project URL and Anon Key
  // These should ideally be in a constant or env file
  await Supabase.initialize(
    url: 'https://dsddwqdixsdhaspfafuy.supabase.co',
    anonKey: 'sb_publishable_vNlyMzHSX84GUhL-JWXqLA_S7shZml_',
  );

  final supabase = Supabase.instance.client;
  getIt.registerLazySingleton<SupabaseClient>(() => supabase);

  /// 🔐 Data Sources
  getIt.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(getIt<SupabaseClient>()),
    instanceName: 'supabase_datasource',
  );

  getIt.registerLazySingleton<UserRemoteDataSource>(
    () => UserRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );
}
