import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:fresh_home_customer/core/injection/injection_container.dart' as di;
import 'package:fresh_home_customer/features/services/presentation/cubit/services_cubit.dart';
import 'package:fresh_home_customer/features/services/presentation/cubit/service_reviews_cubit.dart';
import 'package:fresh_home_customer/features/services/presentation/pages/services_page.dart';
import 'package:fresh_home_customer/features/services/presentation/pages/service_details_page.dart';

class ServicesRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.services,
      name: AppRoutes.services,
      builder: (context, state) {
        final serveid = state.uri.queryParameters['serveid'] ?? '';
        return BlocProvider<ServicesCubit>(
          create: (context) => di.getIt<ServicesCubit>()..getServices(serveid),
          child: ServicesPage(serveid: serveid),
        );
      },
      routes: [
        GoRoute(
          path: AppRoutes.serviceDetails,
          name: AppRoutes.serviceDetails,
          builder: (context, state) {
            final serviceId = state.uri.queryParameters['serviceId'] ?? '';
            final subServiceId = state.uri.queryParameters['subServiceId'] ?? '';
            return MultiBlocProvider(
              providers: [
                BlocProvider<ServicesCubit>(
                  create: (context) => di.getIt<ServicesCubit>()
                    ..getServiceDetails(
                      mainServiceId: serviceId,
                      subserviceId: subServiceId,
                      forceRemote: true,
                    ),
                ),
                BlocProvider<ServiceReviewsCubit>(
                  create: (context) => di.getIt<ServiceReviewsCubit>()
                    ..fetchReviews(serviceId: subServiceId),
                ),
              ],
              child: ServiceDetailsPage(
                serviceId: serviceId,
                subServiceId: subServiceId,
              ),
            );
          },
        ),
      ],
    ),
  ];
}

