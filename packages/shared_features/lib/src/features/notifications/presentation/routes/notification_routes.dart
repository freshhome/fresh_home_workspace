import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import '../cubit/notification_cubit.dart';
import '../pages/notification_center_page.dart';

class NotificationRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.notifications,
      name: AppRoutes.notifications,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<NotificationCubit>()..refresh(),
        child: const NotificationCenterPage(),
      ),
    ),
  ];
}
