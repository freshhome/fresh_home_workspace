import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import 'package:shared/core/constants/app_routes.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/core/routing/navigation_service.dart';
import 'package:shared/core/navigation/navigation_config.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/data/user/models/local/user_hive_model.dart';
import 'package:shared/data/user/mappers/user_roles_mappers.dart';

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
    refreshListenable: GoRouterRefreshStream(
      Supabase.instance.client.auth.onAuthStateChange,
    ),
    redirect: (context, state) {
      final path = state.uri.path;

      // Define public routes
      final publicRoutes = [
        AppRoutes.splash,
        AppRoutes.login,
        AppRoutes.signUp,
        AppRoutes.forgotPassword,
        AppRoutes.resetPassword,
        AppRoutes.onboarding,
      ];

      // Check if current route is public
      final isPublicRoute = publicRoutes.any((route) => path == route);

      // Check if user has active session in Supabase Auth
      final currentUser = Supabase.instance.client.auth.currentUser;
      final isLoggedIn = currentUser != null;

      // Handle unauthenticated state
      if (!isLoggedIn) {
        if (!isPublicRoute) {
          // If trying to access protected route while logged out, redirect to login
          debugPrint('🔒 [Router Guard] Redirecting unauthenticated user to login');
          return AppRoutes.login;
        }
        return null;
      }

      // User is logged in.
      // 1. If trying to access auth pages (login, sign-up, etc.), redirect to home or initial path
      if (isPublicRoute && path != AppRoutes.splash && path != AppRoutes.resetPassword) {
        try {
          final initialPath = GetIt.I<NavigationConfig>().initialPath;
          debugPrint('🔓 [Router Guard] Authenticated user on public page -> redirecting to $initialPath');
          return initialPath;
        } catch (_) {
          return null;
        }
      }

      // 2. Perform role checking (except for customer app since it allows any logged-in user)
      UserRole? defaultRole;
      try {
        defaultRole = GetIt.I<UserRole>(instanceName: 'defaultRole');
      } catch (_) {
        // Fail-safe fallback if not registered yet
      }

      if (defaultRole != null && defaultRole != UserRole.client) {
        UserHiveModel? cachedUser;
        try {
          if (Hive.isBoxOpen(HiveBoxNames.userBox)) {
            final box = Hive.box(HiveBoxNames.userBox);
            cachedUser = box.get('current_user') as UserHiveModel?;
          }
        } catch (e) {
          debugPrint('⚠️ [Router Guard] Error accessing Hive userBox: $e');
        }

        if (cachedUser == null) {
          // If logged in but no profile cached yet, let them remain on splash/pending or redirect to splash to load it
          if (path != AppRoutes.splash && path != AppRoutes.pendingApproval) {
            debugPrint('⚠️ [Router Guard] Authenticated but no cached profile -> redirecting to splash');
            return AppRoutes.splash;
          }
          return null;
        }

        // Map cached role codes to UserRoles
        final userRoles = userRoleFromCode(codes: cachedUser.rolesCodes);
        final hasRequiredRole = userRoles.contains(defaultRole);

        if (!hasRequiredRole) {
          if (path != AppRoutes.pendingApproval) {
            debugPrint('🚫 [Router Guard] User does not have role: ${defaultRole.name} -> redirecting to pending approval');
            return AppRoutes.pendingApproval;
          }
          return null;
        }
      }

      // If user has the required role and goes to /pending-approval, redirect them out
      if (path == AppRoutes.pendingApproval) {
        try {
          final initialPath = GetIt.I<NavigationConfig>().initialPath;
          return initialPath;
        } catch (_) {
          return null;
        }
      }

      // Root path redirect
      if (path == '/') {
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

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen(
          (dynamic _) => notifyListeners(),
        );
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
