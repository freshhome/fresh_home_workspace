import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../cubit/booking_funnel_cubit.dart';
import '../cubit/web_analytics_cubit.dart';
import '../pages/web_analytics_page.dart';

class WebAnalyticsRoutes {
  static const String analyticsPath = '/admin/web-analytics';
  static const String analyticsName = 'admin_web_analytics';

  static List<GoRoute> get routes => [
        GoRoute(
          path: analyticsPath,
          name: analyticsName,
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<WebAnalyticsCubit>(
                  create: (context) =>
                      GetIt.instance<WebAnalyticsCubit>()..loadTodayAnalytics(),
                ),
                BlocProvider<BookingFunnelCubit>(
                  create: (context) =>
                      GetIt.instance<BookingFunnelCubit>()..loadFunnelStats(),
                ),
              ],
              child: const WebAnalyticsPage(),
            );
          },
        ),
      ];
}
