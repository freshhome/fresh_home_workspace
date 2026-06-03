import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/core/constants/app_routes.dart';
import '../authentication_presentation.dart';

class AuthenticationRoutes {
  static final List<GoRoute> routes = [
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.login,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<AuthCubit>(),
        child: const AuthScreen(),
      ),
    ),
    GoRoute(
      // Dedicated route for Supabase OAuth callback to prevent GoRouter from falling back to /
      path: '/login-callback',
      builder: (context, state) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: AppRoutes.forgotPassword,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<AuthCubit>(),
        child: const ForgotPasswordEmailPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.resetPassword,
      name: AppRoutes.resetPassword,
      builder: (context, state) => BlocProvider.value(
        value: GetIt.I<AuthCubit>(),
        child: const ResetPasswordPage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.pendingApproval,
      name: AppRoutes.pendingApproval,
      builder: (context, state) => const PendingApprovalPage(),
    ),
  ];
}
