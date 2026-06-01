import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class EnsureRoleUseCase {
  final UserRepositories userRepositories;
  EnsureRoleUseCase(this.userRepositories);

  Future<Either<Failure, void>> call(String roleName) async {
    return userRepositories.ensureRole(roleName);
  }
}
