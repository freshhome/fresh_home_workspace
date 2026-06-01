import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared/core/network/network_info.dart';
import 'package:shared/core/routing/navigation_service.dart';
import 'supabase_di.dart';
import 'hive_di.dart';

Future<void> setupCoreDI(GetIt getIt) async {
  await setupSupabaseDI(getIt);
  await setupHiveDI(getIt);

  /// 🌐 Network Info
  getIt.registerLazySingleton<InternetConnectionChecker>(
    () => InternetConnectionChecker.instance,
  );
  getIt.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(getIt<InternetConnectionChecker>()),
  );

  /// 📍 Navigation Service
  getIt.registerLazySingleton<NavigationService>(() => NavigationService());
}
