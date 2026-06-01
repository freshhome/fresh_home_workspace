import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class SignOutUseCase {
  final UserRepositories userRepositories;
  SignOutUseCase(this.userRepositories);

  Future<Either<Failure, void>> call() async {
    return userRepositories.signOut();
  }

  Future<User?> getCurrentUser() async {
    return userRepositories.getCurrentUser();
  }
}
