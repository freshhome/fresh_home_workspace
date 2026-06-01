import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';
import 'package:shared_features/src/features/authentication/presentation/authentication_presentation.dart';
import 'package:shared_features/src/features/authentication/data/authentication_data.dart';
import 'package:shared/domain/user/enums/user_role.dart';
import 'package:shared/data/user/datasources/user_remote_datasource.dart';
import 'package:shared_features/src/features/notifications/fcm_token_manager.dart';

Future<void> initAuthDI(
  GetIt getIt, {
  required UserRole defaultRole,
  required String googleRedirectUrl,
}) async {
  // Register default role
  getIt.registerLazySingleton<UserRole>(
    () => defaultRole,
    instanceName: 'defaultRole',
  );

  // Data Sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => SupabaseAuthDataSourceImpl(getIt<SupabaseClient>()),
  );

  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(),
  );

  // Repositories
  getIt.registerLazySingleton<UserRepositories>(
    () => UserRepositoryImpl(
      authDataSource: getIt<AuthRemoteDataSource>(),
      userRemoteDataSource: getIt<UserRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
      defaultRole: defaultRole,
    ),
  );

  // Use Cases
  getIt.registerLazySingleton(() => SignInUseCase(getIt()));
  getIt.registerLazySingleton(() => SignUpUseCase(getIt()));
  getIt.registerLazySingleton(() => ResendVerificationCodeUseCase(getIt()));
  getIt.registerLazySingleton(() => ResetPasswordUseCase(getIt()));
  getIt.registerLazySingleton(() => SignOutUseCase(getIt()));
  getIt.registerLazySingleton(() => SignInWithGoogleUseCase(getIt()));
  getIt.registerLazySingleton(() => EnsureRoleUseCase(getIt()));
  getIt.registerLazySingleton(() => VerifyRoleUseCase(getIt()));

  // Cubit
  getIt.registerLazySingleton(
    () => AuthCubit(
      getIt(), // SignInUseCase
      getIt(), // SignUpUseCase
      getIt(), // ResendVerificationCodeUseCase
      getIt(), // ResetPasswordUseCase
      getIt(), // SignInWithGoogleUseCase
      getIt(), // SignOutUseCase
      getIt(), // StopRealtimeSyncUseCase
      getIt(), // EnsureRoleUseCase
      getIt(), // VerifyRoleUseCase
      getIt<FcmTokenManager>(),
      getIt(instanceName: 'defaultRole'),
      googleRedirectUrl,
    ),
  );
}
