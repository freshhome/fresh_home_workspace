import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/service/use_cases/service/stop_realtime_sync_use_case.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';
import 'package:shared_features/src/features/notifications/fcm_token_manager.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final ResendVerificationCodeUseCase resendVerificationCodeUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SignInWithGoogleUseCase signInWithGoogleUseCase;
  final SignOutUseCase signOutUseCase;
  final StopRealtimeSyncUseCase stopRealtimeSyncUseCase;
  final EnsureRoleUseCase ensureRoleUseCase;
  final VerifyRoleUseCase verifyRoleUseCase;
  final FcmTokenManager fcmTokenManager;
  final UserRole defaultRole;
  final String googleRedirectUrl;
  
  String? _lastEmail;
  String? _lastPassword;
  String? _userId;

  String? get userId => _userId;
  
  AuthCubit(
    this.signInUseCase,
    this.signUpUseCase,
    this.resendVerificationCodeUseCase,
    this.resetPasswordUseCase,
    this.signInWithGoogleUseCase,
    this.signOutUseCase,
    this.stopRealtimeSyncUseCase,
    this.ensureRoleUseCase,
    this.verifyRoleUseCase,
    this.fcmTokenManager,
    this.defaultRole,
    this.googleRedirectUrl,
  ) : super(AuthInitial());

  final pageController = PageController();



  Future<void> signIn({required String email,required String password}) async {
    _lastEmail = email;
    _lastPassword = password;
    emit(AuthLoadingState());
    
    final result = await signInUseCase(email, password);
    
    if (isClosed) return;
    
    await result.fold(
      (failure) async => emit(AuthErrorState(failure)),
      (r) async {
        final currentUser = await signOutUseCase.getCurrentUser();
        if (currentUser == null) {
          emit(AuthErrorState(UnknownFailure(message: 'User session not found')));
          return;
        }

        if (defaultRole == UserRole.client) {
          debugPrint('🚀 [AuthCubit] Client App detected - Skipping role verification');
          _userId = currentUser.uid;
          await _handleSignInSuccess(currentUser.uid);
          emit(SignInSuccess());
          return;
        }

        // After successful sign in, verify if the user has the required role for this app
        // We use the defaultRole for the current app
        final roleResult = await verifyRoleUseCase(defaultRole.name);
        if (isClosed) return;
        
        roleResult.fold(
          (failure) => emit(AuthErrorState(failure)),
          (hasRole) async {
            if (hasRole) {
              _userId = currentUser.uid;
              await _handleSignInSuccess(currentUser.uid);
              emit(SignInSuccess());
            } else {
              emit(AuthPendingRoleState());
            }
          },
        );
      },
    );
  }


  Future<void> signUp({required String email,required String password,required String firstName,required String lastName}) async {
    emit(AuthLoadingState());
    final result = await signUpUseCase(email, password,firstName,lastName);
    if (isClosed) return;
    result.fold((l) => emit(AuthErrorState(l)), (r) => emit(SignUpSuccess()));
  }

  Future<void> resendVerificationCode() async {
    if (_lastEmail == null || _lastPassword == null) return;
    
    emit(AuthLoadingState());
    final result = await resendVerificationCodeUseCase(_lastEmail!, _lastPassword!);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthErrorState(failure)),
      (_) {
         // Re-emit error state with special code to indicate success message should be shown, 
         // OR better, emit a specific success state or handle it in UI.
         // For simplicity and reusing existing dialog logic, let's assume we show success 
         // but we need a way to tell the UI it worked.
         // Let's use a specific success state for this action? 
         // Or just show success dialog via DialogHelper manually if needed.
         // Actually, let's emit a state that listener can pick up.
         emit(ResendVerificationSuccess());
      },
    );
  }

  Future<void> resetPassword({required String email}) async {
    emit(AuthLoadingState());
    final result = await resetPasswordUseCase(email, redirectTo: googleRedirectUrl);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthErrorState(failure)),
      (_) => emit(ResetPasswordSuccess()),
    );
  }

  Future<void> signInWithGoogle() async {
    emit(AuthLoadingState());
    final result = await signInWithGoogleUseCase(redirectTo: googleRedirectUrl);
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthErrorState(failure)),
      (_) => emit(AuthInitial()), // External flow starts
    );
  }

  Future<void> signOut() async {
    emit(AuthLoadingState());
    
    // 🗑️ Delete FCM token BEFORE logout while we are still authenticated
    try {
      final currentUser = await signOutUseCase.getCurrentUser();
      if (currentUser != null) {
        debugPrint('🔔 [AuthCubit] Deleting FCM token for user: ${currentUser.uid}');
        await fcmTokenManager.deleteToken(currentUser.uid);
      }
    } catch (e) {
      debugPrint('⚠️ [AuthCubit] Failed to delete FCM token: $e');
    }

    final result = await signOutUseCase();
    if (isClosed) return;
    result.fold(
      (failure) => emit(AuthErrorState(failure)),
      (_) async {
        debugPrint('🔵 [AuthCubit] Stopping real-time service sync...');
        stopRealtimeSyncUseCase.call();
        
        _userId = null;
        emit(AuthInitial());
      },
    );
  }

  void reset() {
    debugPrint('🔵 [AuthCubit] Resetting auth state to AuthInitial...');
    _userId = null;
    try {
      stopRealtimeSyncUseCase.call();
    } catch (e) {
      debugPrint('⚠️ [AuthCubit] Failed to stop realtime sync: $e');
    }
    emit(AuthInitial());
  }

  Future<void> onAuthCallback(String role) async {
    debugPrint('🔵 [AuthCubit] onAuthCallback started for role: $role');
    emit(AuthLoadingState());
    
    // ✅ Customer App (Client Role) doesn't need role verification
    if (role.toLowerCase() == 'client') {
      debugPrint('🚀 [AuthCubit] Client Role detected - Skipping role verification');
      final currentUser = await signOutUseCase.getCurrentUser();
      if (currentUser != null) {
        _userId = currentUser.uid;
        await _handleSignInSuccess(currentUser.uid);
      }
      emit(SignInSuccess());
      return;
    }
    
    // Check if the user has the required role for the app
    final roleResult = await verifyRoleUseCase(role);
    
    if (isClosed) return;
    
    await roleResult.fold(
      (failure) async {
        debugPrint('❌ [AuthCubit] onAuthCallback - Verify role failed: ${failure.message}');
        emit(AuthErrorState(failure));
      },
      (hasRole) async {
        debugPrint('🔍 [AuthCubit] onAuthCallback - Has required role ($role): $hasRole');
        if (hasRole) {
          final currentUser = await signOutUseCase.getCurrentUser();
          if (currentUser != null) {
             _userId = currentUser.uid;
             await _handleSignInSuccess(currentUser.uid);
          }
          debugPrint('🚀 [AuthCubit] Emitting SignInSuccess');
          emit(SignInSuccess());
        } else {
          debugPrint('⚠️ [AuthCubit] Emitting AuthPendingRoleState');
          emit(AuthPendingRoleState());
        }
      },
    );
  }

  

  void nextPage() => pageController.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  void previousPage() => pageController.previousPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  void goToPage(int index) => pageController.jumpToPage(index);

  Future<void> initializeFcmIfLoggedIn() async {
    final user = await signOutUseCase.getCurrentUser();
    if (user != null) {
      debugPrint('🔔 [AuthCubit] Initializing FCM for existing session: ${user.uid}');
      _userId = user.uid; // Ensure userId is set
      await fcmTokenManager.initialize(user.uid);
    }
  }

  Future<void> _handleSignInSuccess(String userId) async {
    debugPrint('🔔 [AuthCubit] Initializing FCM for user: $userId');
    await fcmTokenManager.initialize(userId);
  }

  @override
  Future<void> close() {
    pageController.dispose();
    return super.close();
  }


}
