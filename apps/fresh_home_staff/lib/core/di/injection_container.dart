import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_features/shared_features.dart';
import '../../features/technician_orders/domain/use_cases/get_all_orders.dart';
import '../../features/technician_orders/presentation/cubit/technician_orders_cubit.dart';
import '../../features/finance/data/data_sources/technician_finance_remote_data_source.dart';
import '../../features/finance/data/repositories/technician_finance_repository_impl.dart';
import '../../features/finance/domain/repositories/technician_finance_repository.dart';
import '../../features/finance/presentation/cubit/technician_finance_cubit.dart';
import '../../features/technician_orders/presentation/routes/technician_orders_routes.dart';
import '../../features/technician_orders/presentation/pages/technician_orders_screen.dart';
import '../../features/home/di/home_di.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/home/presentation/cubit/home_cubit.dart';
import '../../features/home/presentation/routes/home_routes.dart';
import '../../features/technician_schedule/presentation/routes/technician_schedule_routes.dart';
import '../../features/technician_schedule/presentation/cubit/smart_schedule_cubit.dart';
import '../../features/reviews/presentation/routes/technician_reviews_routes.dart';
import '../../features/reviews/presentation/cubit/technician_reviews_cubit.dart';
import '../../features/reviews/domain/use_cases/fetch_technician_reviews_use_case.dart';

final getIt = GetIt.instance;

Future<void> initAppDI() async {
  // Initialize shared features DI with navigation config
  await initSharedFeaturesDI(
    getIt,
    appRole: UserRole.technician,
    googleRedirectUrl: 'com.freshhome.staff://login-callback',
    extraRoutes: [
      ...TechnicianOrdersRoutes.routes,
      ...HomeRoutes.routes,
      ...TechnicianScheduleRoutes.routes,
      ...TechnicianReviewsRoutes.routes,
    ],
    navigationConfig: NavigationConfig(
      items: [
        // Home
        NavigationItem(
          labelKey: 'nav_home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          pageBuilder: (context) => BlocProvider(
            create: (_) => GetIt.instance<HomeCubit>(),
            child: const HomePage(),
          ),
          path: AppRoutes.tabHome,
        ),
        // Technician Orders
        NavigationItem(
          labelKey: 'technician_orders_title',
          icon: Icons.work_outline,
          activeIcon: Icons.work,
          pageBuilder: (context) => BlocProvider.value(
            value: GetIt.instance<TechnicianOrdersCubit>()..loadOrders(),
            child: const TechnicianOrdersScreen(),
          ),
          path: AppRoutes.technicianOrders, // Using technicianOrders to match existing routes
        ),
        // Profile
        NavigationItem(
          labelKey: 'profile_title',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          pageBuilder: (context) => const ProfileDetailScreen(),
          path: AppRoutes.tabProfile,
        ),
        // Settings
        NavigationItem(
          labelKey: 'settings_title',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          pageBuilder: (context) => BlocProvider(
            create: (_) => GetIt.instance<SignOutCubit>(),
            child: const SettingsScreen(),
          ),
          path: AppRoutes.tabSettings,
        ),
      ],
    ),
  );

  // --------------------------------------------------------------------------
  // APP-SPECIFIC FEATURES
  // --------------------------------------------------------------------------

  // Technician Orders Feature
  getIt.registerLazySingleton<TechnicianOrdersCubit>(
    () => TechnicianOrdersCubit(
      getAllOrders: getIt<GetAllOrders>(),
      transitionBooking: getIt<TransitionBookingUseCase>(),
      updateBooking: getIt<UpdateBookingUseCase>(),
      calculatePrice: getIt<CalculatePriceUseCase>(),
    ),
  );

  getIt.registerLazySingleton<TransitionBookingUseCase>(
    () => TransitionBookingUseCase(repository: getIt()),
  );

  getIt.registerLazySingleton<GetAllOrders>(
    () => GetAllOrders(getIt()),
  );

  // Technician Schedule Feature
  getIt.registerFactory<SmartScheduleCubit>(
    () => SmartScheduleCubit(getIt()),
  );

  // Financial feature
  getIt.registerLazySingleton<TechnicianFinanceRemoteDataSource>(
    () => TechnicianFinanceRemoteDataSourceImpl(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<TechnicianFinanceRepository>(
    () => TechnicianFinanceRepositoryImpl(
      getIt<TechnicianFinanceRemoteDataSource>(),
      getIt<SupabaseClient>(),
    ),
  );

  getIt.registerLazySingleton<TechnicianFinanceCubit>(
    () => TechnicianFinanceCubit(getIt<TechnicianFinanceRepository>()),
  );

  // Technician Reviews Feature
  getIt.registerLazySingleton<FetchTechnicianReviewsUseCase>(
    () => FetchTechnicianReviewsUseCase(getIt<ReviewsRepository>()),
  );

  getIt.registerFactory<TechnicianReviewsCubit>(
    () => TechnicianReviewsCubit(
      fetchTechnicianReviewsUseCase: getIt<FetchTechnicianReviewsUseCase>(),
    ),
  );

  // Register local home feature
  await initHomeDI(getIt);
}

