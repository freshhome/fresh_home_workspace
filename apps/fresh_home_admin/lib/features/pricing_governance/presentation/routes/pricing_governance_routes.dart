import 'package:go_router/go_router.dart';
import '../pages/service_pricing_hub_page.dart';

class PricingGovernanceRoutes {
  static const String dashboardPath = '/pricing-governance/:subServiceId';
  static const String dashboardName = 'pricing_governance';

  static List<GoRoute> get routes => [
        GoRoute(
          path: dashboardPath,
          name: dashboardName,
          builder: (context, state) {
            final subServiceId = state.pathParameters['subServiceId'] ?? '';
            return ServicePricingHubPage(subServiceId: subServiceId);
          },
        ),
      ];
}

