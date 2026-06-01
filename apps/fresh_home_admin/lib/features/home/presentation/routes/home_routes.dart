import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';

class HomeRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.home,
      redirect: (context, state) => AppRoutes.tabHome,
    ),
  ];
}
