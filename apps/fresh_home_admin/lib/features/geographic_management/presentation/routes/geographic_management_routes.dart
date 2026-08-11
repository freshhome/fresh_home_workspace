import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../di/geographic_management_di.dart';
import '../pages/admin_geographic_management_screen.dart';

class GeographicManagementRoutes {
  static const String path = '/admin/geographic-management';

  static final List<RouteBase> routes = [
    GoRoute(
      path: path,
      name: 'admin_geographic_management',
      builder: (context, state) => BlocProvider(
        create: (_) => sl<AdminGeographicReferenceCubit>()..loadGovernorates(),
        child: const AdminGeographicManagementScreen(),
      ),
    ),
  ];
}
