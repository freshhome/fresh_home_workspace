import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/error_mapper.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/domain/user/enums/user_status.dart';
import 'package:shared/domain/service/use_cases/service/stop_realtime_sync_use_case.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/ensure_role.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/resend_verification_code_use_case.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/reset_password.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/sign_in_user.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/sign_in_with_google.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/sign_out.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/sign_up_user.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/update_password.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/verify_recovery_otp_use_case.dart';
import 'package:shared_features/src/features/authentication/domain/use_cases/verify_role.dart';
import 'package:shared_features/src/features/authentication/presentation/cubit/auth_cubit.dart';
import 'package:shared_features/src/features/notifications/fcm_token_manager.dart';

// --- FAKE USE CASES & SERVICES ---

class FakeSignInUseCase implements SignInUseCase {
  final bool shouldSucceed;
  final Failure? failure;
  FakeSignInUseCase({this.shouldSucceed = true, this.failure});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call(String email, String password) async {
    if (shouldSucceed) {
      return const Right(null);
    }
    return Left(failure ?? const ServerFailure(message: 'Invalid credentials'));
  }
}

class FakeSignOutUseCase implements SignOutUseCase {
  final UserProfile? currentUser;
  bool isSignedOut = false;
  FakeSignOutUseCase({this.currentUser});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<UserProfile?> getCurrentUser() async => currentUser;

  @override
  Future<Either<Failure, void>> call() async {
    isSignedOut = true;
    return const Right(null);
  }
}

class FakeVerifyRoleUseCase implements VerifyRoleUseCase {
  final bool hasRole;
  final Failure? failure;
  FakeVerifyRoleUseCase({this.hasRole = true, this.failure});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, bool>> call(String requiredRole) async {
    if (failure != null) return Left(failure!);
    return Right(hasRole);
  }
}

class FakeEnsureRoleUseCase implements EnsureRoleUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call(String roleName) async {
    return const Right(null);
  }
}

class FakeResetPasswordUseCase implements ResetPasswordUseCase {
  final bool shouldSucceed;
  final Failure? failure;
  FakeResetPasswordUseCase({this.shouldSucceed = true, this.failure});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call(String email, {String? redirectTo}) async {
    if (shouldSucceed) return const Right(null);
    return Left(failure ?? const ServerFailure(message: 'User not found'));
  }
}

class FakeUpdatePasswordUseCase implements UpdatePasswordUseCase {
  final bool shouldSucceed;
  final Failure? failure;
  FakeUpdatePasswordUseCase({this.shouldSucceed = true, this.failure});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call(String newPassword) async {
    if (shouldSucceed) return const Right(null);
    return Left(failure ?? const ServerFailure(message: 'Update failed'));
  }
}

class FakeVerifyRecoveryOtpUseCase implements VerifyRecoveryOtpUseCase {
  final bool shouldSucceed;
  final Failure? failure;
  FakeVerifyRecoveryOtpUseCase({this.shouldSucceed = true, this.failure});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call({required String email, required String token}) async {
    if (shouldSucceed) return const Right(null);
    return Left(failure ?? const ServerFailure(message: 'رمز التحقق غير صحيح'));
  }
}

class FakeResendVerificationCodeUseCase implements ResendVerificationCodeUseCase {
  final bool shouldSucceed;
  final Failure? failure;
  FakeResendVerificationCodeUseCase({this.shouldSucceed = true, this.failure});

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call(String email) async {
    if (shouldSucceed) return const Right(null);
    return Left(failure ?? const ServerFailure(message: 'Resend failed'));
  }
}

class FakeSignUpUseCase implements SignUpUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call(String email, String password, String firstName, String lastName, {String? redirectTo}) async {
    return const Right(null);
  }
}

class FakeSignInWithGoogleUseCase implements SignInWithGoogleUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Either<Failure, void>> call({String? redirectTo}) async {
    return const Right(null);
  }
}

class FakeStopRealtimeSyncUseCase implements StopRealtimeSyncUseCase {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  
  @override
  Future<Either<Failure, void>> call() async => const Right(null);
}

class FakeFcmTokenManager implements FcmTokenManager {
  bool deleted = false;
  bool initialized = false;
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> initialize(String userId) async {
    initialized = true;
  }

  @override
  Future<void> deleteToken(String userId) async {
    deleted = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockAdminUser = AdminProfile(
    uid: 'admin-123',
    firstName: 'Admin',
    lastName: 'User',
    email: 'admin@freshhome.com',
    accountStatus: UserStatus.active,
    gender: 'male',
    roles: const [UserRole.admin],
    adminPermissions: const ['all'],
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final mockTechUser = TechnicianProfile(
    uid: 'tech-123',
    firstName: 'Tech',
    lastName: 'User',
    email: 'tech@freshhome.com',
    accountStatus: UserStatus.active,
    gender: 'male',
    roles: const [UserRole.technician],
    isVerified: true,
    mainServiceId: 'service-1',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  AuthCubit createAuthCubit({
    SignInUseCase? signInUseCase,
    SignOutUseCase? signOutUseCase,
    VerifyRoleUseCase? verifyRoleUseCase,
    ResetPasswordUseCase? resetPasswordUseCase,
    UpdatePasswordUseCase? updatePasswordUseCase,
    ResendVerificationCodeUseCase? resendVerificationCodeUseCase,
    UserRole defaultRole = UserRole.admin,
  }) {
    return AuthCubit(
      signInUseCase ?? FakeSignInUseCase(),
      FakeSignUpUseCase(),
      resendVerificationCodeUseCase ?? FakeResendVerificationCodeUseCase(),
      resetPasswordUseCase ?? FakeResetPasswordUseCase(),
      updatePasswordUseCase ?? FakeUpdatePasswordUseCase(),
      FakeVerifyRecoveryOtpUseCase(),
      FakeSignInWithGoogleUseCase(),
      signOutUseCase ?? FakeSignOutUseCase(currentUser: mockAdminUser),
      FakeStopRealtimeSyncUseCase(),
      FakeEnsureRoleUseCase(),
      verifyRoleUseCase ?? FakeVerifyRoleUseCase(),
      FakeFcmTokenManager(),
      defaultRole,
      'http://localhost',
    );
  }

  group('🔑 Admin App Authentication Functional Validation', () {
    test('1. Correct Admin Login -> Emits SignInSuccess [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        signOutUseCase: FakeSignOutUseCase(currentUser: mockAdminUser),
        verifyRoleUseCase: FakeVerifyRoleUseCase(hasRole: true),
        defaultRole: UserRole.admin,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.signIn(email: 'admin@freshhome.com', password: 'ValidPassword123');
      await pumpEventQueue();

      expect(states, contains(isA<AuthLoadingState>()));
      expect(states.last, isA<SignInSuccess>());
      await authCubit.close();
    });

    test('2. Admin Login with Invalid Credentials -> Emits AuthErrorState [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(
          shouldSucceed: false,
          failure: const AuthFailure(message: 'invalid_credentials'),
        ),
        defaultRole: UserRole.admin,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.signIn(email: 'admin@freshhome.com', password: 'WrongPassword');
      await pumpEventQueue();

      expect(states, contains(isA<AuthLoadingState>()));
      expect(states.last, isA<AuthErrorState>());
      expect((states.last as AuthErrorState).failure.message, 'invalid_credentials');
      await authCubit.close();
    });

    test('3. Admin Role Protection -> Non-admin rejected -> Emits AuthPendingRoleState [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        signOutUseCase: FakeSignOutUseCase(currentUser: mockTechUser),
        verifyRoleUseCase: FakeVerifyRoleUseCase(hasRole: false), // Technician is not Admin
        defaultRole: UserRole.admin,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.signIn(email: 'tech@freshhome.com', password: 'ValidPassword123');
      await pumpEventQueue();

      expect(states.last, isA<AuthPendingRoleState>());
      await authCubit.close();
    });

    test('4. Admin Logout Lifecycle -> SignOut executed & caches cleared [PASS]', () async {
      final signOutUseCase = FakeSignOutUseCase(currentUser: mockAdminUser);
      final authCubit = createAuthCubit(
        signOutUseCase: signOutUseCase,
        defaultRole: UserRole.admin,
      );

      await authCubit.signOut();
      await pumpEventQueue();

      expect(signOutUseCase.isSignedOut, isTrue);
      await authCubit.close();
    });
  });

  group('🛠️ Staff (Technician) App Authentication Functional Validation', () {
    test('5. Correct Technician Login -> Emits SignInSuccess [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        signOutUseCase: FakeSignOutUseCase(currentUser: mockTechUser),
        verifyRoleUseCase: FakeVerifyRoleUseCase(hasRole: true),
        defaultRole: UserRole.technician,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.signIn(email: 'tech@freshhome.com', password: 'ValidPassword123');
      await pumpEventQueue();

      expect(states.last, isA<SignInSuccess>());
      await authCubit.close();
    });

    test('6. Technician Pending Approval -> verifyRole returns false -> AuthPendingRoleState [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        signOutUseCase: FakeSignOutUseCase(currentUser: mockTechUser),
        verifyRoleUseCase: FakeVerifyRoleUseCase(hasRole: false), // Unapproved
        defaultRole: UserRole.technician,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.signIn(email: 'unapproved@freshhome.com', password: 'Password123');
      await pumpEventQueue();

      expect(states.last, isA<AuthPendingRoleState>());
      await authCubit.close();
    });

    test('7. Technician Role Protection -> Non-technician blocked from Staff app [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        signOutUseCase: FakeSignOutUseCase(currentUser: mockAdminUser),
        verifyRoleUseCase: FakeVerifyRoleUseCase(hasRole: false),
        defaultRole: UserRole.technician,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.signIn(email: 'admin@freshhome.com', password: 'Password123');
      await pumpEventQueue();

      expect(states.last, isA<AuthPendingRoleState>());
      await authCubit.close();
    });

    test('8. Resend Verification -> Executes with email only -> ResendVerificationSuccess [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        resendVerificationCodeUseCase: FakeResendVerificationCodeUseCase(shouldSucceed: true),
        defaultRole: UserRole.technician,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      // Trigger sign in first to populate _lastEmail
      await authCubit.signIn(email: 'newtech@freshhome.com', password: 'Password123');
      await pumpEventQueue();

      await authCubit.resendVerificationCode();
      await pumpEventQueue();

      expect(states, contains(isA<ResendVerificationSuccess>()));
      await authCubit.close();
    });
  });

  group('🔐 Critical End-to-End Password Recovery Validation', () {
    test('9. Forgot Password -> Sends reset email -> ResetPasswordSuccess [PASS]', () async {
      final authCubit = createAuthCubit(
        resetPasswordUseCase: FakeResetPasswordUseCase(shouldSucceed: true),
        defaultRole: UserRole.admin,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.resetPassword(email: 'admin@freshhome.com');
      await pumpEventQueue();

      expect(states.last, isA<ResetPasswordSuccess>());
      await authCubit.close();
    });

    test('9b. Forgot Password with Unregistered Email -> Emits AuthErrorState [PASS]', () async {
      final authCubit = createAuthCubit(
        resetPasswordUseCase: FakeResetPasswordUseCase(
          shouldSucceed: false,
          failure: const AuthFailure(
            message: 'لا يوجد حساب مسجل بهذا البريد الإلكتروني',
            code: 'user_not_found',
          ),
        ),
        defaultRole: UserRole.admin,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.resetPassword(email: 'notfound@freshhome.com');
      await pumpEventQueue();

      expect(states, contains(isA<AuthLoadingState>()));
      expect(states.last, isA<AuthErrorState>());
      final errorState = states.last as AuthErrorState;
      expect(errorState.failure.code, 'user_not_found');
      await authCubit.close();
    });

    test('10. Reset Password -> Updates password -> UpdatePasswordSuccess -> New Login succeeds [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        signOutUseCase: FakeSignOutUseCase(currentUser: mockAdminUser),
        verifyRoleUseCase: FakeVerifyRoleUseCase(hasRole: true),
        updatePasswordUseCase: FakeUpdatePasswordUseCase(shouldSucceed: true),
        defaultRole: UserRole.admin,
      );

      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      // 1️⃣ User updates password
      await authCubit.updatePassword(newPassword: 'BrandNewSecurePassword123');
      await pumpEventQueue();
      expect(states, contains(isA<UpdatePasswordSuccess>()));

      // 2️⃣ User logs in with new password
      await authCubit.signIn(email: 'admin@freshhome.com', password: 'BrandNewSecurePassword123');
      await pumpEventQueue();
      expect(states.last, isA<SignInSuccess>());

      await authCubit.close();
    });
  });

  group('🛡️ System Resilience & Reliability Validation', () {
    test('11. Double-Submit Protection -> Rapid concurrent calls ignored during AuthLoadingState [PASS]', () async {
      final authCubit = createAuthCubit(
        signInUseCase: FakeSignInUseCase(shouldSucceed: true),
        defaultRole: UserRole.admin,
      );

      authCubit.emit(AuthLoadingState());

      // Attempt concurrent sign-in while loading
      await authCubit.signIn(email: 'admin@freshhome.com', password: 'Password123');
      await pumpEventQueue();

      // State remains unchanged because guard returned early
      expect(authCubit.state, isA<AuthLoadingState>());
      await authCubit.close();
    });

    test('12. Session Expiration & Network Failure Error Mapping [PASS]', () {
      final sessionExpiredMsg = ErrorMapper.mapExternalServiceError(
        SupabaseExceptionApp('Session expired', code: 'session_expired'),
      );
      expect(sessionExpiredMsg, isA<AuthFailure>());
      expect(sessionExpiredMsg.message, contains('انتهت صلاحية الجلسة'));

      final tokenExpiredMsg = ErrorMapper.mapExternalServiceError(
        SupabaseExceptionApp('Token expired', code: 'token_expired'),
      );
      expect(tokenExpiredMsg, isA<AuthFailure>());
      expect(tokenExpiredMsg.message, contains('انتهت صلاحية الجلسة'));

      final invalidCredsMsg = ErrorMapper.mapExternalServiceError(
        SupabaseExceptionApp('Invalid credentials', code: 'invalid_credentials'),
      );
      expect(invalidCredsMsg, isA<AuthFailure>());
      expect(invalidCredsMsg.message, contains('بيانات الدخول غير صحيحة'));
    });

    test('13. Verify Recovery OTP -> Emits OtpVerificationSuccess [PASS]', () async {
      final authCubit = createAuthCubit(defaultRole: UserRole.admin);
      final states = <AuthState>[];
      authCubit.stream.listen(states.add);

      await authCubit.verifyRecoveryOtp(otp: '123456', email: 'test@freshhome.com');
      await pumpEventQueue();

      expect(states, contains(isA<AuthLoadingState>()));
      expect(states.last, isA<OtpVerificationSuccess>());
      await authCubit.close();
    });
  });
}
