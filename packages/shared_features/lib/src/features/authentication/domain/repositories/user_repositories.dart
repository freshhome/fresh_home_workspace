import 'package:fpdart/fpdart.dart';

import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user.dart';

abstract class UserRepositories {
  Future<Either<Failure, User>> signUp(String email, String password,String firstName,String lastName);
  Future<Either<Failure, void>> signIn(String email, String password);
  Future<Either<Failure, void>> signOut();
  Future<Either<Failure, void>> resendVerificationCode(String email, String password);
  Future<Either<Failure, void>> resetPassword(String email, {required String redirectTo});
  Future<Either<Failure, void>> signInWithGoogle({required String redirectTo});
  Future<Either<Failure, void>> ensureRole(String roleName);
  Future<Either<Failure, bool>> verifyRole(String roleName);
  Future<User?> getCurrentUser();
}
