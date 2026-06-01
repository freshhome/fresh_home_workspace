import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/admin_sub_services_cubit.dart';
import 'package:fresh_home_admin/features/services_management/presentation/cubit/services_management_cubit.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import '../cubit/admin_dashboard_cubit.dart';
import '../pages/admin_dashboard_page.dart';
import '../pages/technician_details_page.dart';

class AdminDashboardRoutes {
  static const String dashboard = 'admin_dashboard';
  static const String technicianDetails = 'admin_technician_details';

  static List<GoRoute> get routes => [
        GoRoute(
          path: '/admin-dashboard',
          name: dashboard,
          builder: (context, state) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => GetIt.instance<AdminDashboardCubit>()..loadDashboard(),
              ),
              BlocProvider(
                create: (_) => GetIt.instance<ServicesManagementCubit>()..loadServices(),
              ),
              BlocProvider(
                create: (_) => GetIt.instance<AdminSubServicesCubit>(),
              ),
            ],
            child: const AdminDashboardPage(),
          ),
          routes: [
            GoRoute(
              path: 'technicians',
              name: technicianDetails,
              builder: (context, state) {
                final date = state.extra as DateTime? ?? DateTime.now();
                return BlocProvider.value(
                  value: GetIt.instance<AdminDashboardCubit>()..loadTechnicianDetailsForDate(date),
                  child: TechnicianDetailsPage(date: date),
                );
              },
            ),
          ],
        ),
      ];
}
