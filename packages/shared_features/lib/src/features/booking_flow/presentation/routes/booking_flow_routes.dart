import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/data/service/repositories/service_repository_impl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_features/src/features/booking_flow/domain/booking_flow_config.dart';
import 'package:shared_features/src/features/booking_flow/presentation/cubit/booking_cubit_params.dart';
import 'package:shared_features/src/features/booking_flow/presentation/cubit/booking_flow_cubit.dart';
import 'package:shared_features/src/features/booking_flow/presentation/pages/booking_page.dart';

/// Shared booking flow route.
///
/// Usage — push with [BookingFlowConfig] as `extra`:
/// ```dart
/// context.pushNamed(
///   AppRoutes.bookingFlow,
///   extra: BookingFlowConfig(
///     mode: BookingFlowMode.customer,
///     actorId: userId,
///     preSelectedService: bookedService,
///     initialServicePrice: priceEntity,
///   ),
/// );
/// ```
class BookingFlowRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: '/${AppRoutes.bookingFlow}',
      name: AppRoutes.bookingFlow,
      builder: (context, state) {
        final BookingFlowConfig config;
        if (state.extra is BookingFlowConfig) {
          config = state.extra as BookingFlowConfig;
        } else {
          final isAdmin = ServiceRepositoryImpl.isAdminMode;
          String currentUserId = '';
          try {
            currentUserId =
                Supabase.instance.client.auth.currentUser?.id ?? '';
          } catch (_) {}
          config = BookingFlowConfig(
            mode: isAdmin ? BookingFlowMode.admin : BookingFlowMode.customer,
            actorId: currentUserId,
          );
        }

        return BlocProvider<BookingFlowCubit>(
          create: (_) => GetIt.instance<BookingFlowCubit>(
            param1: BookingCubitParams(config: config),
          ),
          child: const BookingPage(),
        );
      },
    ),
  ];
}
