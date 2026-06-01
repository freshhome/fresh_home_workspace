import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared/shared.dart';
import 'package:get_it/get_it.dart';
import '../pages/technician_order_details_screen.dart';
import '../cubit/technician_orders_cubit.dart';

import '../pages/technician_financial_portal_page.dart';

class TechnicianOrdersRoutes {
  static const String technicianOrders = '/technician-orders';
  static const String technicianOrderDetails = 'technician_order_details';
  static const String technicianFinancialPortal = 'technician_financial_portal';

  static List<RouteBase> get routes => [
        GoRoute(
          path: '/technician-financial-portal',
          name: technicianFinancialPortal,
          builder: (context, state) => const TechnicianFinancialPortalPage(),
        ),
        GoRoute(
          path: '/technician-order-details/:id',
          name: AppRoutes.orderDetails,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            final bookingId = state.pathParameters['id'];
            final cubit = extra?['cubit'] as TechnicianOrdersCubit?;
            final order = extra?['order'] as Booking?;

            final screen = TechnicianOrderDetailsScreen(
              order: order,
              bookingId: bookingId,
              showSensitiveDetails: extra?['showSensitiveDetails'] as bool? ?? false,
            );

            if (cubit != null) {
              return BlocProvider.value(
                value: cubit,
                child: screen,
              );
            }
            
            return BlocProvider(
              create: (_) => GetIt.instance<TechnicianOrdersCubit>(),
              child: screen,
            );
          },
        ),
      ];
}
