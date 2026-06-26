import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import '../../features/services_management/presentation/routes/services_management_routes.dart';
import '../../features/home/di/home_di.dart';
import '../../features/home/presentation/routes/home_routes.dart';
import '../../features/supabase_services/presentation/routes/supabase_services_routes.dart';
import '../../features/supabase_services/presentation/cubit/supabase_services_cubit.dart';
import '../../features/user_management/di/user_management_di.dart';
import '../../features/user_management/presentation/routes/user_management_routes.dart';
import '../../features/booking_management/presentation/routes/booking_management_routes.dart';
import '../../features/booking_management/di/booking_management_di.dart';
import '../../features/services_management/presentation/services_management_presentation.dart';
import 'package:shared/data/service/datasources/service_remote_datasource.dart';
import '../../features/notification_management/di/notification_management_di.dart';
import 'package:fresh_home_admin/features/home/presentation/pages/home_page.dart';
import '../../features/admin_dashboard/di/admin_dashboard_di.dart';
import '../../features/admin_dashboard/presentation/routes/admin_dashboard_routes.dart';
import '../../features/pricing_governance/di/pricing_governance_di.dart';
import '../../features/pricing_governance/presentation/routes/pricing_governance_routes.dart';
import '../../features/finance/di/admin_finance_di.dart';
import '../../features/finance/presentation/routes/admin_finance_routes.dart';
import '../../features/reviews_management/domain/use_cases/fetch_admin_reviews_use_case.dart';
import '../../features/reviews_management/domain/use_cases/approve_review_use_case.dart';
import '../../features/reviews_management/presentation/cubit/reviews_moderation_cubit.dart';
import '../../features/reviews_management/presentation/routes/reviews_moderation_routes.dart';
import '../../features/whatsapp_settings/domain/repositories/whatsapp_settings_repository.dart';
import 'package:shared/data/service/repositories/service_repository_impl.dart';
import '../../features/whatsapp_settings/data/repositories/whatsapp_settings_repository_impl.dart';
import '../../features/whatsapp_settings/presentation/cubit/whatsapp_settings_cubit.dart';

final getIt = GetIt.instance;

Future<void> initAppDI() async {
  // تفعيل وضع المسؤول للـ ServiceRepository لمنع فلترة كاش شجرة الخدمات للإدارة
  ServiceRepositoryImpl.isAdminMode = true;

  // Initialize shared features DI with navigation config for Admin
  await initSharedFeaturesDI(
    getIt,
    appRole: UserRole.admin,
    googleRedirectUrl: 'com.freshhome.admin://login-callback',
    extraRoutes: [
      ...ServicesManagementRoutes.routes,
      ...HomeRoutes.routes,
      ...SupabaseServicesRoutes.routes,
      ...BookingManagementRoutes.routes,
      ...UserManagementRoutes.routes,
      ...AdminDashboardRoutes.routes,
      ...PricingGovernanceRoutes.routes,
      ...AdminFinanceRoutes.routes,
      ...ReviewsModerationRoutes.routes,
    ],
    navigationConfig: NavigationConfig(
      items: [
        // Home (Dashboard)
        NavigationItem(
          labelKey: 'nav_home',
          icon: Icons.home_outlined,
          activeIcon: Icons.home,
          pageBuilder: (context) => const HomePage(),
          path: AppRoutes.tabHome,
        ),
        // Profile
        NavigationItem(
          labelKey: 'nav_profile',
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
          pageBuilder: (context) => const ProfileDetailScreen(),
          path: AppRoutes.tabProfile,
        ),
        // Settings
        NavigationItem(
          labelKey: 'settings_title',
          icon: Icons.settings_outlined,
          activeIcon: Icons.settings,
          pageBuilder: (context) => BlocProvider(
            create: (_) => getIt<SignOutCubit>(),
            child: const SettingsScreen(),
          ),
          path: AppRoutes.tabSettings,
        ),
      ],
    ),
  );

  // --------------------------------------------------------------------------
  // SERVICES MANAGEMENT FEATURE
  // --------------------------------------------------------------------------
  
  // Register Cubits
  getIt.registerFactory<ServicesManagementCubit>(
    () => ServicesManagementCubit(
      getRootServicesUseCase: getIt(),
      getChildrenUseCase: getIt(),
      addServiceUseCase: getIt(),
      updateServiceUseCase: getIt(),
    ),
  );

  getIt.registerFactory<AdminSubServicesCubit>(
    () => AdminSubServicesCubit(
      getChildrenUseCase: getIt(),
      addServiceUseCase: getIt(),
      updateServiceUseCase: getIt(),
    ),
  );

  // --------------------------------------------------------------------------
  // USER MANAGEMENT FEATURE (Moved from shared_features)
  // --------------------------------------------------------------------------
  await initUserManagementDI();

  getIt.registerFactory<SupabaseServicesCubit>(
    () => SupabaseServicesCubit(
      getIt<ServiceRemoteDataSource>(instanceName: 'supabase_datasource'),
    ),
  );

  // Register local home feature
  await initHomeDI(getIt);

  // --------------------------------------------------------------------------
  // BOOKING MANAGEMENT FEATURE
  // --------------------------------------------------------------------------
  await initBookingManagementDI(getIt);

  // --------------------------------------------------------------------------
  // NOTIFICATION MANAGEMENT FEATURE
  // --------------------------------------------------------------------------
  await initNotificationManagementDI(getIt);

  // --------------------------------------------------------------------------
  // ADMIN DASHBOARD FEATURE
  // --------------------------------------------------------------------------
  setupAdminDashboardDI(getIt);

  // --------------------------------------------------------------------------
  // PRICING GOVERNANCE FEATURE
  // --------------------------------------------------------------------------
  initPricingGovernance();

  // --------------------------------------------------------------------------
  // ADMIN FINANCE FEATURE
  // --------------------------------------------------------------------------
  initAdminFinanceDI(getIt);

  // --------------------------------------------------------------------------
  // REVIEWS MODERATION FEATURE
  // --------------------------------------------------------------------------
  getIt.registerLazySingleton<FetchAdminReviewsUseCase>(
    () => FetchAdminReviewsUseCase(repository: getIt()),
  );
  getIt.registerLazySingleton<ApproveReviewUseCase>(
    () => ApproveReviewUseCase(repository: getIt()),
  );
  getIt.registerFactory<ReviewsModerationCubit>(
    () => ReviewsModerationCubit(
      fetchAdminReviewsUseCase: getIt(),
      approveReviewUseCase: getIt(),
    ),
  );

  // --------------------------------------------------------------------------
  // WHATSAPP SETTINGS FEATURE
  // --------------------------------------------------------------------------
  getIt.registerLazySingleton<WhatsAppSettingsRepository>(
    () => WhatsAppSettingsRepositoryImpl(),
  );
  getIt.registerFactory<WhatsAppSettingsCubit>(
    () => WhatsAppSettingsCubit(repository: getIt()),
  );
}
