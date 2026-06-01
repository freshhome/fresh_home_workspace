import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';

class AuthListener extends StatefulWidget {
  final Widget child;
  final String appRole;

  const AuthListener({
    super.key,
    required this.child,
    required this.appRole,
  });

  @override
  State<AuthListener> createState() => _AuthListenerState();
}

class _AuthListenerState extends State<AuthListener> {
  StreamSubscription<supabase.AuthState>? _authSubscription;
  supabase.AuthChangeEvent? _lastEvent;

  @override
  void initState() {
    super.initState();
    
    // Ensure FCM is initialized even if we have an existing session
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthCubit>().initializeFcmIfLoggedIn();
    });
    
    _authSubscription = supabase.Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final supabase.AuthChangeEvent event = data.event;
      final supabase.Session? session = data.session;
      final supabase.User? user = session?.user ?? supabase.Supabase.instance.client.auth.currentUser;

      _lastEvent = event;

      final providers = user?.identities?.map((i) => i.provider).toList();
      final identities = user?.identities?.map((i) => '${i.provider}:${i.identityId}').toList();

      debugPrint('================ AUTH DEBUG ================');
      debugPrint('DEBUG AUTH STATE CHANGE EVENT');
      debugPrint('eventType: ${event.name}');
      debugPrint('userId: ${user?.id}');
      debugPrint('email: ${user?.email}');
      debugPrint('providers: $providers');
      debugPrint('identities: $identities');
      debugPrint('app_metadata: ${user?.appMetadata}');
      debugPrint('user_metadata: ${user?.userMetadata}');
      debugPrint('============================================');

      if ((event == supabase.AuthChangeEvent.signedIn || event == supabase.AuthChangeEvent.initialSession) && session != null) {
        final authCubit = context.read<AuthCubit>();
        
        // Prevent redundant calls if already loading or verified
        if (authCubit.state is AuthLoadingState || authCubit.state is SignInSuccess) {
          return;
        }

        debugPrint('🔵 [AuthListener] User signed in event detected - Verifying role for app: ${widget.appRole}');
        if (mounted) {
          authCubit.onAuthCallback(appRoleToString(widget.appRole));
        }
      } else if (event == supabase.AuthChangeEvent.signedOut) {
        final authCubit = context.read<AuthCubit>();
        debugPrint('🔴 [AuthListener] User signed out event detected - Resetting AuthCubit state');
        if (mounted && authCubit.state is! AuthInitial) {
          authCubit.reset();
        }
      }
    });
  }

  String appRoleToString(String role) {
    // Standardize mapping to DB roles
    final normalized = role.toLowerCase();
    if (normalized == 'admin') return 'admin';
    if (normalized == 'technician' || normalized == 'staff') return 'technician';
    if (normalized == 'client' || normalized == 'customer') return 'client';
    return normalized;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        final router = GetIt.I<AppRouterConfig>().router;
        final currentPath = router.routerDelegate.currentConfiguration.uri.path;

        if (state is AuthPendingRoleState) {
          if (currentPath == AppRoutes.pendingApproval) return;
          
          debugPrint('⏳ [AuthListener] Pending Role detected - Redirecting to PendingApprovalPage');
          router.go(AppRoutes.pendingApproval);
        } else if (state is SignInSuccess) {
          // If we are on the login page, let AuthScreen handle the dialog and navigation
          if (currentPath == AppRoutes.login && _lastEvent != supabase.AuthChangeEvent.initialSession) {
            debugPrint('ℹ️ [AuthListener] SignInSuccess detected while on Login page - Letting AuthScreen handle it');
            return;
          }
          
          if (currentPath == AppRoutes.home || currentPath == AppRoutes.tabHome) return;
          
          final initialPath = GetIt.I<NavigationConfig>().initialPath;
          debugPrint('🚀 [AuthListener] SignInSuccess detected - Redirecting to initial path: $initialPath');
          router.go(initialPath);
        }
      },
      child: widget.child,
    );
  }
}
