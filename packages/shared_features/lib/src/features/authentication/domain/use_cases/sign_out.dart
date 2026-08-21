import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

import 'package:shared_features/src/features/notifications/fcm_token_manager.dart';

class SignOutUseCase {
  final UserRepositories userRepositories;
  final FcmTokenManager fcmTokenManager;

  SignOutUseCase(this.userRepositories, this.fcmTokenManager);

  Future<Either<Failure, void>> call() async {
    try {
      final currentUser = await userRepositories.getCurrentUser();
      if (currentUser != null) {
        await fcmTokenManager.deleteToken(currentUser.uid);
      }
    } catch (_) {}
    return userRepositories.signOut();
  }

  Future<UserProfile?> getCurrentUser() async {
    return userRepositories.getCurrentUser();
  }
}
