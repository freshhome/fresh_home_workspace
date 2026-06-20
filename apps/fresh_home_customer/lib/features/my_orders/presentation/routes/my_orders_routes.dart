import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';

import '../cubit/my_orders_cubit.dart';
import '../cubit/edit_order_cubit.dart';
import '../cubit/submit_review_cubit.dart';
import '../pages/my_orders_screen.dart';
import '../pages/order_details_screen.dart';
import '../pages/edit_schedule_screen.dart';
import '../pages/edit_address_screen.dart';

class MyOrdersRoutes {
  static final List<RouteBase> routes = [
    GoRoute(
      path: AppRoutes.myOrders,
      name: AppRoutes.myOrders,
      builder: (context, state) => BlocProvider(
        create: (context) => GetIt.instance<MyOrdersCubit>()..loadOrders(),
        child: const MyOrdersScreen(),
      ),
    ),
    GoRoute(
      path: '${AppRoutes.orderDetails}/:id',
      name: AppRoutes.orderDetails,
      builder: (context, state) {
        final order = state.extra as Booking?;
        final orderId = state.pathParameters['id'];
        
        return MultiBlocProvider(
          providers: [
            BlocProvider.value(value: GetIt.instance<MyOrdersCubit>()),
            BlocProvider(create: (_) => GetIt.instance<EditOrderCubit>()),
            BlocProvider(create: (_) => GetIt.instance<SubmitReviewCubit>()),
          ],
          child: OrderDetailsScreen(
            order: order,
            orderId: orderId,
          ),
        );
      },
    ),

    GoRoute(
      path: AppRoutes.editSchedule,
      name: AppRoutes.editSchedule,
      builder: (context, state) {
        final order = state.extra as Booking;
        return BlocProvider(
          create: (_) => GetIt.instance<EditOrderCubit>(),
          child: EditScheduleScreen(order: order),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.editAddress,
      name: AppRoutes.editAddress,
      builder: (context, state) {
        final order = state.extra as Booking;
        return BlocProvider(
          create: (_) => GetIt.instance<EditOrderCubit>(),
          child: EditAddressScreen(order: order),
        );
      },
    ),
  ];
}
