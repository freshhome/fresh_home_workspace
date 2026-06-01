import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class ResendVerificationCodeUseCase {
  final UserRepositories repository;

  ResendVerificationCodeUseCase(this.repository);

  Future<Either<Failure, void>> call(String email, String password) async {
    return await repository.resendVerificationCode(email, password);
  }
}
