import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
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

      // 1. Sync Services (Centralized in Splash) - Only for Customer App
      if (appRole == UserRole.client) {
        debugPrint('🔵 [SplashCubit] Client App detected - Syncing services...');
        try {
          final syncResult = await syncServicesUseCase.call().timeout(const Duration(seconds: 20));
          syncResult.fold(
            (failure) => debugPrint('⚠️ [SplashCubit] Service sync failed: ${failure.message}'),
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
      } else {
        debugPrint('🚀 [SplashCubit] App role is ${appRole.name} - Skipping service sync');
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
            // ✅ Customer App (Client Role) doesn't need role verification
            if (appRole == UserRole.client) {
              debugPrint('🚀 [SplashCubit] Client App detected - Skipping role verification');
              emit(SplashUserLoggedInState());
              return;
            }

            debugPrint('✅ [SplashCubit] User is logged in, verifying role for app: ${appRole.name}');
            // 3. Verify user has the required role for this specific app with timeout
            debugPrint('🔵 [SplashCubit] Verifying role: ${appRole.name}...');
            final roleResult = await verifyRoleUseCase(appRole.name)
                .timeout(const Duration(seconds: 10), onTimeout: () {
              debugPrint('⚠️ [SplashCubit] Role verification TIMED OUT');
              return const Left(NetworkFailure(message: 'Role verification timeout'));
            });
            
            roleResult.fold(
              (failure) {
                debugPrint('❌ [SplashCubit] Role verification failed: ${failure.message}');
                emit(SplashErrorState(failure));
                // Fallback: if we can't verify role, don't let them in, but don't stay stuck
                debugPrint('⚠️ [SplashCubit] Falling back to SplashUserPendingApprovalState');
                emit(SplashUserPendingApprovalState());
              },
              (hasRole) {
                debugPrint('🔍 [SplashCubit] roleResult - Has required role (${appRole.name}): $hasRole');
                if (hasRole) {
                  debugPrint('🚀 [SplashCubit] Emitting SplashUserLoggedInState');
                  emit(SplashUserLoggedInState());
                } else {
                  debugPrint('⚠️ [SplashCubit] Emitting SplashUserPendingApprovalState');
                  emit(SplashUserPendingApprovalState());
                }
              },
            );
          } else {
            debugPrint('ℹ️ [SplashCubit] User NOT logged in');
            
            // ✅ Check for Onboarding (Only for Customer App)
            if (appRole == UserRole.client) {
              final onboardingResult = await isOnboardingCompletedUseCase();
              final isCompleted = onboardingResult.getOrElse((_) => true);
              
              if (!isCompleted) {
                debugPrint('🎨 [SplashCubit] Onboarding NOT completed - Redirecting to Onboarding');
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
