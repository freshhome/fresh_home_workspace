import 'package:go_router/go_router.dart';
import '../pages/dispatch_lab_page.dart';

class DispatchLabRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/admin/dispatch-lab',
      name: 'admin_dispatch_lab',
      builder: (context, state) => const DispatchLabPage(),
    ),
  ];
}
