import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../pages/supabase_services_page.dart';
import '../pages/supabase_sub_services_page.dart';
import '../pages/supabase_service_details_page.dart';
import '../cubit/supabase_services_cubit.dart';

class SupabaseServicesRoutes {
  static List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.adminSupabaseServices,
      name: AppRoutes.adminSupabaseServices,
      builder: (context, state) => BlocProvider(
        create: (context) => di.getIt<SupabaseServicesCubit>()..loadMainServices(),
        child: const SupabaseServicesPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminSupabaseSubServices,
      name: AppRoutes.adminSupabaseSubServices,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return SupabaseSubServicesPage(
          cubit: args['cubit'] as SupabaseServicesCubit,
          mainServiceId: args['mainServiceId'] as String,
          mainServiceTitle: args['mainServiceTitle'] as String,
        );
      },
    ),
    GoRoute(
      path: AppRoutes.adminSupabaseServiceDetails,
      name: AppRoutes.adminSupabaseServiceDetails,
      builder: (context, state) {
        final args = state.extra as Map<String, dynamic>;
        return SupabaseServiceDetailsPage(
          cubit: args['cubit'] as SupabaseServicesCubit,
        );
      },
    ),
  ];
}
