import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';

import 'package:shared_features/shared_features.dart';

import 'package:fresh_home_customer/features/services/presentation/cubit/services_cubit.dart';
import 'package:fresh_home_customer/features/services/presentation/routes/services_routes.dart';
import 'package:fresh_home_customer/features/my_orders/di/my_orders_di.dart';
import 'package:fresh_home_customer/features/my_orders/presentation/cubit/my_orders_cubit.dart';
import 'package:fresh_home_customer/features/my_orders/presentation/routes/my_orders_routes.dart';
import 'package:fresh_home_customer/features/my_orders/presentation/pages/my_orders_screen.dart';
import 'package:fresh_home_customer/features/home/di/home_di.dart';
import 'package:fresh_home_customer/features/home/presentation/home_presentation.dart';
import 'package:fresh_home_customer/features/home/presentation/routes/home_routes.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fresh_home_customer/core/services/migration_service.dart';


final getIt = GetIt.instance;

Future<void> initAppDI() async {
  // --------------------------------------------------------------------------
  // CORE SERVICES & MIGRATION
  // --------------------------------------------------------------------------

  // Register SharedPreferences
  final sharedPrefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPrefs);

  // Register and Run Migration (Production/Release only)
  getIt.registerLazySingleton<MigrationService>(
    () => HiveMigrationService(getIt<SharedPreferences>()),
  );

  if (kReleaseMode) {
    await getIt<MigrationService>().migrate();
  }

  // Initialize shared features with navigation config
  await initSharedFeaturesDI(
    getIt,
    appRole: UserRole.client,
    googleRedirectUrl: 'com.freshhome.customer://login-callback',
    extraRoutes: [
      ...ServicesRoutes.routes,
      ...HomeRoutes.routes,
      ...MyOrdersRoutes.routes,
    ],
    navigationConfig: NavigationConfig(
      items: [
        // Home
        NavigationItem(
          labelKey: 'nav_home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          path: AppRoutes.tabHome,
          pageBuilder: (context) => BlocProvider(
            create: (_) => GetIt.instance<HomeCubit>(),
            child: const HomePage(),
          ),
        ),
        // My Orders
        NavigationItem(
          labelKey: 'nav_my_orders',
          icon: Icons.receipt_long_outlined,
          activeIcon: Icons.receipt_long,
          path: AppRoutes.tabOrders,
          pageBuilder: (context) => BlocProvider(
            create: (_) => GetIt.instance<MyOrdersCubit>()..loadOrders(),
            child: const MyOrdersScreen(),
          ),
        ),
        // Profile
        NavigationItem(
          labelKey: 'profile_title',
          icon: Icons.person_outline,
          activeIcon: Icons.person,
          path: AppRoutes.tabProfile,
          pageBuilder: (context) => const ProfileDetailScreen(),
        ),
        // Settings
        NavigationItem(
          labelKey: 'settings_title',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          path: AppRoutes.tabSettings,
          pageBuilder: (context) => BlocProvider(
            create: (_) => GetIt.instance<SignOutCubit>(),
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),
  );

  // Register local home feature
  await initHomeDI(getIt);

  // Register my_orders feature
  await initMyOrdersDI(getIt);

  // --------------------------------------------------------------------------
  // APP-SPECIFIC FEATURES
  // --------------------------------------------------------------------------

  // Services
  getIt.registerFactory<ServicesCubit>(
    () => ServicesCubit(
      getMainServicesUseCase: getIt<GetMainServicesUseCase>(),
      getSubServicesUseCase: getIt<GetSubServicesUseCase>(),
      getSubServiceByIdUseCase: getIt<GetSubServiceByIdUseCase>(),
    ),
  );
}
