import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import '../pages/admin_finance_dashboard_page.dart';
import '../cubit/admin_finance_cubit.dart';
import '../cubit/admin_reports_cubit.dart';

class AdminFinanceRoutes {
  static const String financeDashboardPath = '/admin/finance';
  static const String financeDashboardName = 'admin_finance_dashboard';

  static List<GoRoute> get routes => [
        GoRoute(
          path: financeDashboardPath,
          name: financeDashboardName,
          builder: (context, state) {
            return MultiBlocProvider(
              providers: [
                BlocProvider<AdminFinanceCubit>(
                  create: (context) => GetIt.instance<AdminFinanceCubit>()..loadFinancialData(),
                ),
                BlocProvider<AdminReportsCubit>(
                  create: (context) => GetIt.instance<AdminReportsCubit>()..loadReports(),
                ),
              ],
              child: const AdminFinanceDashboardPage(),
            );
          },
        ),
      ];
}
