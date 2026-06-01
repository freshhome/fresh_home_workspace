import 'package:go_router/go_router.dart';
import 'package:shared_features/src/features/splash/presentation/routes/splash_routes.dart';
import 'package:shared_features/src/features/onboarding/presentation/routes/onboarding_routes.dart';
import 'package:shared_features/src/features/authentication/presentation/routes/authentication_routes.dart';
import 'package:shared_features/src/features/profile/presentation/routes/profile_routes.dart';
import 'package:shared_features/src/features/settings/presentation/routes/settings_routes.dart';
import 'package:shared_features/src/features/booking_flow/presentation/routes/booking_flow_routes.dart';
import 'package:shared_features/src/features/notifications/presentation/routes/notification_routes.dart';

class SharedFeaturesRoutes {
  static final List<RouteBase> routes = [
    ...SplashRoutes.routes,
    ...OnboardingRoutes.routes,
    ...AuthenticationRoutes.routes,
    ...ProfileRoutes.routes,
    ...SettingsRoutes.routes,
    ...BookingFlowRoutes.routes,
    ...NotificationRoutes.routes,
  ];
}
