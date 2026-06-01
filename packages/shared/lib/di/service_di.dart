import 'package:get_it/get_it.dart';
import 'package:shared/core/network/network_info.dart';
import 'package:shared/data/service/datasources/service_local_datasource.dart';
import 'package:shared/data/service/datasources/service_pending_action_datasource.dart';
import 'package:shared/data/service/datasources/service_realtime_sync_datasource.dart';
import 'package:shared/data/service/datasources/service_remote_datasource.dart';
import 'package:shared/data/service/repositories/service_repository_impl.dart';
import 'package:shared/domain/service/repositories/service_repository.dart';
import 'package:shared/domain/service/use_cases/service/add_main_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/add_sub_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/delete_main_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/delete_sub_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_main_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_sub_service_by_id_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_sub_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/search_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/start_realtime_sync_use_case.dart';
import 'package:shared/domain/service/use_cases/service/stop_realtime_sync_use_case.dart';
import 'package:shared/domain/service/use_cases/service/sync_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/update_main_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/update_sub_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_root_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_children_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_bookable_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_service_by_id_use_case.dart';
import 'package:shared/domain/service/use_cases/service/add_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/update_service_use_case.dart';
import 'package:shared/domain/service/use_cases/service/upload_service_image_use_case.dart';
import 'package:shared/domain/service/use_cases/service/delete_service_image_use_case.dart';
import 'package:shared/domain/service/use_cases/service/get_shared_icons_use_case.dart';
import 'package:shared/domain/service/use_cases/service/insert_shared_icon_use_case.dart';
import 'package:shared/domain/service/use_cases/service/delete_shared_icon_use_case.dart';
import 'package:shared/domain/service/use_cases/technician/get_technicians_for_service_use_case.dart';
import 'package:shared/domain/service/use_cases/technician/get_technicians_use_case.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void setupServiceDI(GetIt getIt) {
  // Data sources
  getIt.registerLazySingleton<ServiceRemoteDataSource>(
    () => ServiceRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<ServiceLocalDataSource>(
    () => ServiceLocalDataSourceImpl(),
  );

  getIt.registerLazySingleton<ServicePendingActionDataSource>(
    () => ServicePendingActionDataSourceImpl(),
  );

  getIt.registerLazySingleton<ServiceRealtimeSyncDataSource>(
    () => ServiceRealtimeSyncDataSourceImpl(
      supabase: getIt<SupabaseClient>(),
      localDataSource: getIt<ServiceLocalDataSource>(),
      pendingActionDataSource: getIt<ServicePendingActionDataSource>(),
    ),
  );

  // Repository
  getIt.registerLazySingleton<ServiceRepository>(
    () => ServiceRepositoryImpl(
      remoteDataSource: getIt<ServiceRemoteDataSource>(),
      localDataSource: getIt<ServiceLocalDataSource>(),
      pendingActionDataSource: getIt<ServicePendingActionDataSource>(),
      realtimeSyncDataSource: getIt<ServiceRealtimeSyncDataSource>(),
      networkInfo: getIt<NetworkInfo>(),
    ),
  );

  // Use cases
  getIt.registerLazySingleton<AddMainServiceUseCase>(
    () => AddMainServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<AddSubServiceUseCase>(
    () => AddSubServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<DeleteMainServiceUseCase>(
    () => DeleteMainServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<DeleteSubServiceUseCase>(
    () => DeleteSubServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetMainServicesUseCase>(
    () => GetMainServicesUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetSubServiceByIdUseCase>(
    () => GetSubServiceByIdUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetSubServicesUseCase>(
    () => GetSubServicesUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<SearchServicesUseCase>(
    () => SearchServicesUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<SyncServicesUseCase>(
    () => SyncServicesUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<StartRealtimeSyncUseCase>(
    () => StartRealtimeSyncUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<StopRealtimeSyncUseCase>(
    () => StopRealtimeSyncUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<UpdateMainServiceUseCase>(
    () => UpdateMainServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<UpdateSubServiceUseCase>(
    () => UpdateSubServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetTechniciansUseCase>(
    () => GetTechniciansUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetTechniciansForServiceUseCase>(
    () => GetTechniciansForServiceUseCase(repository: getIt<ServiceRepository>()),
  );

  // New Tree-Based Use Cases
  getIt.registerLazySingleton<GetRootServicesUseCase>(
    () => GetRootServicesUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetChildrenUseCase>(
    () => GetChildrenUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetBookableServicesUseCase>(
    () => GetBookableServicesUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetServiceByIdUseCase>(
    () => GetServiceByIdUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<AddServiceUseCase>(
    () => AddServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<UpdateServiceUseCase>(
    () => UpdateServiceUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<UploadServiceImageUseCase>(
    () => UploadServiceImageUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<DeleteServiceImageUseCase>(
    () => DeleteServiceImageUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<GetSharedIconsUseCase>(
    () => GetSharedIconsUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<InsertSharedIconUseCase>(
    () => InsertSharedIconUseCase(repository: getIt<ServiceRepository>()),
  );
  getIt.registerLazySingleton<DeleteSharedIconUseCase>(
    () => DeleteSharedIconUseCase(repository: getIt<ServiceRepository>()),
  );
}
