import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/data/service/datasources/service_remote_datasource.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared/core/config/app_config.dart';

Future<void> setupSupabaseDI(GetIt getIt) async {
  /// 📦 Supabase Client
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
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
