import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/use_cases/service/sync_services_use_case.dart';
import 'package:shared/domain/service/use_cases/service/start_realtime_sync_use_case.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/verify_role.dart';
import 'package:shared_features/src/features/onboarding/domain/use_cases/is_onboarding_completed_use_case.dart';
import 'package:shared_features/src/features/splash/domain/splash_domain.dart';

part 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final IsUserLoggedInUseCase isUserLoggedInUseCase;
  final IsOnboardingCompletedUseCase isOnboardingCompletedUseCase;
  final SyncServicesUseCase syncServicesUseCase;
  final StartRealtimeSyncUseCase startRealtimeSyncUseCase;
  final VerifyRoleUseCase verifyRoleUseCase;
  final UserRole appRole;

  SplashCubit(
    this.isUserLoggedInUseCase,
    this.isOnboardingCompletedUseCase,
    this.syncServicesUseCase,
    this.startRealtimeSyncUseCase,
    this.verifyRoleUseCase,
    this.appRole,
  ) : super(SplashInitial());

  Future<void> getCurrentUser() async {
    try {
      emit(SplashLoadingState());
      debugPrint('🚀 [SplashCubit] Starting getCurrentUser...');

      // 1. Sync Services (Centralized in Splash) - For all roles (client, admin, technician)
      debugPrint(
        '🔵 [SplashCubit] Syncing services for role ${appRole.name}...',
      );
      try {
        final syncResult = await syncServicesUseCase.call().timeout(
          const Duration(seconds: 20),
        );
        syncResult.fold(
          (failure) => debugPrint(
            '⚠️ [SplashCubit] Service sync failed: ${failure.message}',
          ),
          (success) {
            debugPrint('✅ [SplashCubit] Service sync completed successfully');
            // Start listening to realtime database changes so UI reflects remote updates
            debugPrint('🔵 [SplashCubit] Starting real-time service sync...');
            startRealtimeSyncUseCase.call();
          },
        );
      } catch (e) {
        debugPrint('⚠️ [SplashCubit] Service sync timed out: $e');
      }

      // 2. Check if user is logged in
      debugPrint('🔵 [SplashCubit] Checking auth status...');
      final result = await isUserLoggedInUseCase.call();

      await result.fold(
        (failure) async {
          debugPrint('❌ [SplashCubit] Auth check failed: ${failure.message}');
          emit(SplashErrorState(failure));
          // Fallback to avoid getting stuck
          await Future.delayed(const Duration(seconds: 2));
          emit(SplashUserNotLoggedInState());
        },
        (isLoggedIn) async {
          if (isLoggedIn) {
            // ✅ Read role directly from Supabase JWT claims (Zero Round-Trip Verification)
            final session = Supabase.instance.client.auth.currentSession;
            final appMetadata = session?.user.appMetadata ?? {};
            final rolesClaim = appMetadata['roles'];
            final userRoleClaim = appMetadata['user_role']?.toString();

            debugPrint('🔑 [SplashCubit] JWT app_metadata: $appMetadata');

            bool hasRole = false;
            if (rolesClaim is List) {
              hasRole = rolesClaim.any(
                (r) => r.toString().toLowerCase() == appRole.name.toLowerCase(),
              );
            } else if (rolesClaim is String) {
              hasRole = rolesClaim.toLowerCase() == appRole.name.toLowerCase();
            } else if (userRoleClaim != null) {
              hasRole =
                  userRoleClaim.toLowerCase() == appRole.name.toLowerCase();
            }

            debugPrint(
              '🎯 [SplashCubit] Required Role: ${appRole.name}, Local JWT verification result: $hasRole',
            );

            if (hasRole) {
              debugPrint('🚀 [SplashCubit] Emitting SplashUserLoggedInState');
              emit(SplashUserLoggedInState());
            } else {
              debugPrint(
                '⚠️ [SplashCubit] Emitting SplashUserPendingApprovalState',
              );
              emit(SplashUserPendingApprovalState());
            }
          } else {
            debugPrint('ℹ️ [SplashCubit] User NOT logged in');

            // ✅ Check for Onboarding (Only for Customer App)
            if (appRole == UserRole.client) {
              final onboardingResult = await isOnboardingCompletedUseCase();
              final isCompleted = onboardingResult.getOrElse((_) => true);

              if (!isCompleted) {
                debugPrint(
                  '🎨 [SplashCubit] Onboarding NOT completed - Redirecting to Onboarding',
                );
                emit(SplashOnboardingState());
                return;
              }
            }

            emit(SplashUserNotLoggedInState());
          }
        },
      );
    } catch (e) {
      debugPrint('☢️ [SplashCubit] CRITICAL ERROR in getCurrentUser: $e');
      emit(SplashErrorState(UnknownFailure(message: e.toString())));
      // Final fallback
      emit(SplashUserNotLoggedInState());
    }
  }
}
