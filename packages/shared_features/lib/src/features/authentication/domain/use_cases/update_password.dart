import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class UpdatePasswordUseCase {
  final UserRepositories userRepositories;

  UpdatePasswordUseCase(this.userRepositories);

  Future<Either<Failure, void>> call(String newPassword) async {
    return userRepositories.updatePassword(newPassword);
  }
}
