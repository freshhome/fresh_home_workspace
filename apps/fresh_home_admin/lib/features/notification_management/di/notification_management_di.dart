import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/notification_remote_datasource.dart';
import '../data/repositories_impl/notification_repository_impl.dart';
import '../domain/repositories/notification_management_repository.dart';
import '../domain/use_cases/campaign_use_cases.dart';
import '../presentation/cubit/notification_management_cubit.dart';

Future<void> initNotificationManagementDI(GetIt getIt) async {
  // Data Sources
  getIt.registerLazySingleton<NotificationManagementRemoteDataSource>(
    () => NotificationManagementRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  // Repositories
  getIt.registerLazySingleton<NotificationManagementRepository>(
    () => NotificationManagementRepositoryImpl(getIt()),
  );

  // Use Cases
  getIt.registerLazySingleton(() => GetCampaignsUseCase(getIt()));
  getIt.registerLazySingleton(() => SubmitCampaignUseCase(getIt()));
  getIt.registerLazySingleton(() => RetryCampaignUseCase(getIt()));
  getIt.registerLazySingleton(() => UploadCampaignImageUseCase(getIt()));

  // Cubits
  getIt.registerFactory<NotificationManagementCubit>(
    () => NotificationManagementCubit(
      getCampaignsUseCase: getIt(),
      submitCampaignUseCase: getIt(),
      retryCampaignUseCase: getIt(),
      uploadCampaignImageUseCase: getIt(),
    ),
  );
}
