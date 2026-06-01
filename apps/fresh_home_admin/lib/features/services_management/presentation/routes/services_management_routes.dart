import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';

import '../../../../core/di/injection_container.dart' as di;
import '../services_management_presentation.dart';

class ServicesManagementRoutes {
  static List<RouteBase> get routes => [
    GoRoute(
      path: AppRoutes.servicesManagement,
      name: AppRoutes.servicesManagement,
      builder: (context, state) => BlocProvider(
        create: (_) => di.getIt<ServicesManagementCubit>()..loadServices(),
        child: const ServicesManagementPage(),
      ),
      routes: [
        GoRoute(
          path: 'sub-services',
          name: AppRoutes.adminSubServices,
          builder: (context, state) => BlocProvider(
            create: (_) => di.getIt<ServicesManagementCubit>()..loadServices(),
            child: const ServicesManagementPage(),
          ),
        ),
        GoRoute(
          path: 'service-form',
          name: AppRoutes.adminServiceForm,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            final child = ServiceConfiguratorWizardPage(
              initialData: args['initialData'] as ServiceEntity?,
              onSubmit: args['onSubmit'] as Future<void> Function(dynamic, BuildContext),
            );
            if (args['cubit'] != null && args['cubit'] is ServicesManagementCubit) {
              return BlocProvider.value(
                value: args['cubit'] as ServicesManagementCubit,
                child: child,
              );
            }
            return child;
          },
        ),
        GoRoute(
          path: 'sub-service-form',
          name: AppRoutes.adminSubServiceForm,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            final child = ServiceConfiguratorWizardPage(
              defaultParentId: args['categoryId'] as String?,
              initialData: args['initialData'] as SubServiceEntity?,
              onSubmit: args['onSubmit'] as Future<void> Function(dynamic, BuildContext),
            );
            if (args['cubit'] != null && args['cubit'] is AdminSubServicesCubit) {
              return BlocProvider.value(
                value: args['cubit'] as AdminSubServicesCubit,
                child: child,
              );
            }
            return child;
          },
        ),
        GoRoute(
          path: 'sub-service-details-editor',
          name: AppRoutes.adminSubServiceDetailsEditor,
          builder: (context, state) {
            final args = state.extra as Map<String, dynamic>;
            final child = ServiceConfiguratorWizardPage(
              initialData: args['subService'] as SubServiceEntity?,
              onSubmit: args['onSave'] as Future<void> Function(dynamic, BuildContext),
            );
            if (args['cubit'] != null && args['cubit'] is AdminSubServicesCubit) {
              return BlocProvider.value(
                value: args['cubit'] as AdminSubServicesCubit,
                child: child,
              );
            }
            return child;
          },
        ),
      ],
    ),
  ];
}

