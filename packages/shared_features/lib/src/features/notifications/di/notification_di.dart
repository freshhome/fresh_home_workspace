import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/notification_remote_data_source.dart';
import '../data/repositories/notification_repository_impl.dart';
import '../domain/repositories/notification_repository.dart';
import '../domain/usecases/watch_notifications_use_case.dart';
import '../domain/usecases/mark_notification_read_use_case.dart';
import '../domain/usecases/manage_fcm_token_use_case.dart';
import '../presentation/cubit/notification_cubit.dart';

void initNotificationsDI(GetIt getIt) {
  // Data Sources
  getIt.registerLazySingleton<NotificationRemoteDataSource>(
    () => NotificationRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<NotificationRepository>(
    () => NotificationRepositoryImpl(getIt<NotificationRemoteDataSource>()),
  );

  // Use Cases
  getIt.registerLazySingleton<WatchNotificationsUseCase>(
    () => WatchNotificationsUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerLazySingleton<MarkNotificationReadUseCase>(
    () => MarkNotificationReadUseCase(getIt<NotificationRepository>()),
  );

  getIt.registerLazySingleton<ManageFcmTokenUseCase>(
    () => ManageFcmTokenUseCase(getIt<NotificationRepository>()),
  );

  // Cubits
  getIt.registerLazySingleton<NotificationCubit>(
    () => NotificationCubit(
      watchUseCase: getIt<WatchNotificationsUseCase>(),
      markReadUseCase: getIt<MarkNotificationReadUseCase>(),
      supabaseClient: getIt<SupabaseClient>(),
    ),
  );
}
