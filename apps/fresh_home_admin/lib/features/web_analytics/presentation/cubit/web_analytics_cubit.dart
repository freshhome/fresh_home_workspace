import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_today_analytics_use_case.dart';
import 'web_analytics_state.dart';

class WebAnalyticsCubit extends Cubit<WebAnalyticsState> {
  final GetTodayAnalyticsUseCase getTodayAnalyticsUseCase;

  WebAnalyticsCubit({required this.getTodayAnalyticsUseCase})
      : super(const WebAnalyticsInitial());

  Future<void> loadTodayAnalytics() async {
    debugPrint('📊 [WebAnalyticsCubit] Triggered loadTodayAnalytics()...');
    emit(const WebAnalyticsLoading());

    final result = await getTodayAnalyticsUseCase();
    result.fold(
      (failure) {
        debugPrint('❌ [WebAnalyticsCubit] Failed to load analytics: ${failure.message}');
        emit(WebAnalyticsError(failure.message));
      },
      (analytics) {
        debugPrint('✅ [WebAnalyticsCubit] Loaded successfully: '
            '${analytics.totalUsers} users, ${analytics.totalViews} views, '
            '${analytics.pages.length} pages recorded.');
        emit(WebAnalyticsLoaded(analytics));
      },
    );
  }
}
