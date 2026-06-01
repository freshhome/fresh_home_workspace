import 'package:go_router/go_router.dart';
import 'package:shared/core/constants/app_routes.dart';
import '../onboarding_presentation.dart';

class OnboardingRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: AppRoutes.onboarding,
      name: AppRoutes.onboarding,
      builder: (context, state) => OnboardingPage(),
    ),
  ];
}
