import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/repositories/user_repositories.dart';

class VerifyRecoveryOtpUseCase {
  final UserRepositories repository;

  VerifyRecoveryOtpUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String email,
    required String token,
  }) async {
    return await repository.verifyRecoveryOtp(email: email, token: token);
  }
}
