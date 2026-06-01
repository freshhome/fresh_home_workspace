import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/src/features/notifications/domain/usecases/manage_fcm_token_use_case.dart';
import 'package:shared_features/src/features/splash/di/splash_di.dart';
import 'package:shared_features/src/features/authentication/di/auth_di.dart';
import 'package:shared_features/src/features/profile/di/profile_di.dart';
import 'package:shared_features/src/features/settings/di/settings_di.dart';
import 'package:shared_features/src/features/onboarding/di/onboarding_di.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_features/src/shared_features_routes.dart';
import 'package:shared_features/src/features/notifications/fcm_token_manager.dart';
import 'package:shared_features/src/features/notifications/firebase_messaging_handler.dart';
import '../presentation/layouts/main_layout.dart';
import 'package:shared_features/src/features/booking_flow/di/booking_flow_di.dart';
import 'package:shared_features/src/features/notifications/di/notification_di.dart';
import 'package:shared_features/src/features/notifications/presentation/cubit/notification_cubit.dart';

Future<void> initSharedFeaturesDI(
  GetIt getIt, {
  required UserRole appRole,
  required String googleRedirectUrl,
  List<RouteBase> extraRoutes = const [],
  NavigationConfig? navigationConfig,
}) async {
  /// 🏗️ Core Shared DI
  await initSharedDI(getIt);

  await initOnboardingDI(getIt);
  await initSplashDI(getIt, appRole: appRole);
  await initAuthDI(getIt, defaultRole: appRole, googleRedirectUrl: googleRedirectUrl);
  await initProfileDI(getIt);
  await initSettingsDI(getIt);
  await initBookingFlowDI(getIt);
  initNotificationsDI(getIt);

  /// 🚦 Router Configuration
  getIt.registerLazySingleton<AppRouterConfig>(
    () => AppRouterConfig(
      navigationService: getIt<NavigationService>(),
      featureRoutes: [
        ...SharedFeaturesRoutes.routes,
        ...extraRoutes,
      ],
    ),
  );

  /// 🧭 Navigation Configuration
  if (navigationConfig != null) {
    getIt.registerSingleton<NavigationConfig>(navigationConfig);
    
    // Register the unified layout builder for the router shell
    getIt.registerFactory<Widget Function(StatefulNavigationShell)>(
      () => (shell) => MainLayout(navigationShell: shell),
      instanceName: 'shellBuilder',
    );
  }

  /// 🔔 Notification & FCM Configuration
  getIt.registerLazySingleton<FcmTokenManager>(
    () => FcmTokenManager(getIt<ManageFcmTokenUseCase>()),
  );

  getIt.registerLazySingleton<FirebaseMessagingHandler>(
    () => FirebaseMessagingHandler(
      getIt<NotificationCubit>(),
      getIt<NavigationService>(),
      appRole,
    ),
  );
}
