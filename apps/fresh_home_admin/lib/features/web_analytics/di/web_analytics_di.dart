import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/analytics_remote_data_source.dart';
import '../data/datasources/booking_funnel_remote_data_source.dart';
import '../data/repositories/web_analytics_repository_impl.dart';
import '../domain/repositories/web_analytics_repository.dart';
import '../domain/usecases/get_booking_funnel_stats_use_case.dart';
import '../domain/usecases/get_today_analytics_use_case.dart';
import '../presentation/cubit/booking_funnel_cubit.dart';
import '../presentation/cubit/web_analytics_cubit.dart';

void initWebAnalyticsDI(GetIt getIt) {
  // HTTP Client
  if (!getIt.isRegistered<http.Client>()) {
    getIt.registerLazySingleton<http.Client>(() => http.Client());
  }

  // Data Sources
  if (!getIt.isRegistered<AnalyticsRemoteDataSource>()) {
    getIt.registerLazySingleton<AnalyticsRemoteDataSource>(
      () => AnalyticsRemoteDataSourceImpl(
        client: getIt<http.Client>(),
        baseUrl: 'https://www.freshhomeeg.com',
      ),
    );
  }

  if (!getIt.isRegistered<BookingFunnelRemoteDataSource>()) {
    getIt.registerLazySingleton<BookingFunnelRemoteDataSource>(
      () => BookingFunnelRemoteDataSourceImpl(
        supabaseClient: getIt<SupabaseClient>(),
      ),
    );
  }

  // Repository
  if (!getIt.isRegistered<WebAnalyticsRepository>()) {
    getIt.registerLazySingleton<WebAnalyticsRepository>(
      () => WebAnalyticsRepositoryImpl(
        remoteDataSource: getIt<AnalyticsRemoteDataSource>(),
        funnelRemoteDataSource: getIt<BookingFunnelRemoteDataSource>(),
      ),
    );
  }

  // UseCases
  if (!getIt.isRegistered<GetTodayAnalyticsUseCase>()) {
    getIt.registerLazySingleton<GetTodayAnalyticsUseCase>(
      () => GetTodayAnalyticsUseCase(
        repository: getIt<WebAnalyticsRepository>(),
      ),
    );
  }

  if (!getIt.isRegistered<GetBookingFunnelStatsUseCase>()) {
    getIt.registerLazySingleton<GetBookingFunnelStatsUseCase>(
      () => GetBookingFunnelStatsUseCase(
        repository: getIt<WebAnalyticsRepository>(),
      ),
    );
  }

  // Cubits (Factory)
  if (!getIt.isRegistered<WebAnalyticsCubit>()) {
    getIt.registerFactory<WebAnalyticsCubit>(
      () => WebAnalyticsCubit(
        getTodayAnalyticsUseCase: getIt<GetTodayAnalyticsUseCase>(),
      ),
    );
  }

  if (!getIt.isRegistered<BookingFunnelCubit>()) {
    getIt.registerFactory<BookingFunnelCubit>(
      () => BookingFunnelCubit(
        getBookingFunnelStatsUseCase: getIt<GetBookingFunnelStatsUseCase>(),
      ),
    );
  }
}
