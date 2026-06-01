import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class SignInWithGoogleUseCase {
  final UserRepositories userRepositories;
  SignInWithGoogleUseCase(this.userRepositories);

  Future<Either<Failure, void>> call({required String redirectTo}) async {
    return userRepositories.signInWithGoogle(redirectTo: redirectTo);
  }
}
