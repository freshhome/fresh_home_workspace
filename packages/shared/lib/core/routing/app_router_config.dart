import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/core/routing/navigation_service.dart';
import 'package:shared/core/navigation/navigation_config.dart';

class AppRouterConfig {
  final NavigationService _navigationService;
  final List<RouteBase> _featureRoutes;

  AppRouterConfig({
    required NavigationService navigationService,
    required List<RouteBase> featureRoutes,
  })  : _navigationService = navigationService,
        _featureRoutes = featureRoutes;

  late final GoRouter router = GoRouter(
    navigatorKey: _navigationService.navigatorKey,
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      // Redirect root to initial path if we are logged in (handled by AuthListener mostly, but good as a fail-safe)
      if (state.uri.path == '/') {
        try {
          return GetIt.I<NavigationConfig>().initialPath;
        } catch (_) {
          return null;
        }
      }
      return null;
    },
    routes: [
      ..._featureRoutes,
      _buildShellRoute(),
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text("404")),
      body: Center(child: Text("Page not found: ${state.uri.path}")),
    ),
  );

  RouteBase _buildShellRoute() {
    final config = GetIt.I<NavigationConfig>();
    
    if (config.items.isEmpty) {
      return GoRoute(
        path: '/_none',
        builder: (context, state) => const Scaffold(body: Center(child: Text('No Navigation Config'))),
      );
    }

    return StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return NavigationShellWidget(navigationShell: navigationShell);
      },
      branches: config.items.map((item) {
        // Ensure path starts with / if it's a top-level branch in this shell
        final path = item.path.startsWith('/') ? item.path : '/${item.path}';
        return StatefulShellBranch(
          routes: [
            GoRoute(
              path: path,
              builder: (context, state) => item.pageBuilder(context),
              routes: item.subRoutes ?? [],
            ),
          ],
        );
      }).toList(),
    );
  }
}

/// A placeholder widget that should be replaced/extended by the apps
class NavigationShellWidget extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const NavigationShellWidget({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    // This is a fail-safe. Normally, apps should provide their own MainLayout.
    // But since we want to unify, we can use a DI-provided shell layout.
    try {
      final shellBuilder = GetIt.I<Widget Function(StatefulNavigationShell)>(instanceName: 'shellBuilder');
      return shellBuilder(navigationShell);
    } catch (_) {
      return navigationShell;
    }
  }
}
