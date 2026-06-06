import 'package:go_router/go_router.dart';
import '../pages/service_pricing_hub_page.dart';
import '../pages/pricing_services_list_page.dart';

class PricingGovernanceRoutes {
  static const String servicesListPath = '/pricing-governance';
  static const String servicesListName = 'pricing_services_list';
  static const String dashboardPath = '/pricing-governance/:subServiceId';
  static const String dashboardName = 'pricing_governance';

  static List<GoRoute> get routes => [
        GoRoute(
          path: servicesListPath,
          name: servicesListName,
          builder: (context, state) => const PricingServicesListPage(),
        ),
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

