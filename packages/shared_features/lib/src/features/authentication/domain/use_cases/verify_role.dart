import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class VerifyRoleUseCase {
  final UserRepositories userRepositories;
  VerifyRoleUseCase(this.userRepositories);

  Future<Either<Failure, bool>> call(String roleName) async {
    return userRepositories.verifyRole(roleName);
  }
}
