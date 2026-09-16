import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../data/datasources/analytics_remote_data_source.dart';
import '../data/repositories/web_analytics_repository_impl.dart';
import '../domain/repositories/web_analytics_repository.dart';
import '../domain/usecases/get_today_analytics_use_case.dart';
import '../presentation/cubit/web_analytics_cubit.dart';

void initWebAnalyticsDI(GetIt getIt) {
  // HTTP Client
  if (!getIt.isRegistered<http.Client>()) {
    getIt.registerLazySingleton<http.Client>(() => http.Client());
  }

  // Data Source
  if (!getIt.isRegistered<AnalyticsRemoteDataSource>()) {
    getIt.registerLazySingleton<AnalyticsRemoteDataSource>(
      () => AnalyticsRemoteDataSourceImpl(
        client: getIt<http.Client>(),
        baseUrl: 'https://www.freshhomeeg.com',
      ),
    );
  }

  // Repository
  if (!getIt.isRegistered<WebAnalyticsRepository>()) {
    getIt.registerLazySingleton<WebAnalyticsRepository>(
      () => WebAnalyticsRepositoryImpl(
        remoteDataSource: getIt<AnalyticsRemoteDataSource>(),
      ),
    );
  }

  // UseCase
  if (!getIt.isRegistered<GetTodayAnalyticsUseCase>()) {
    getIt.registerLazySingleton<GetTodayAnalyticsUseCase>(
      () => GetTodayAnalyticsUseCase(
        repository: getIt<WebAnalyticsRepository>(),
      ),
    );
  }

  // Cubit (Factory)
  if (!getIt.isRegistered<WebAnalyticsCubit>()) {
    getIt.registerFactory<WebAnalyticsCubit>(
      () => WebAnalyticsCubit(
        getTodayAnalyticsUseCase: getIt<GetTodayAnalyticsUseCase>(),
      ),
    );
  }
}
