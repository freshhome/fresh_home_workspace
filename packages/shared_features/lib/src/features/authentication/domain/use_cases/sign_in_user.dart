
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class SignInUseCase {
  final UserRepositories userRepositories;
  SignInUseCase(this.userRepositories);

Future<Either<Failure, void>> call(String email, String password) async {
    return userRepositories.signIn(email, password);
  }
}