import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class SignUpUseCase {
  final UserRepositories userRepositories;

  SignUpUseCase(this.userRepositories);
  Future<Either<Failure, void>> call(
    String email,
    String password,
    String firstName,
    String lastName,
  ) async {
    return userRepositories.signUp(email, password, firstName, lastName);
  }
}
