import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/authentication/domain/authentication_domain.dart';

class ResetPasswordUseCase {
  final UserRepositories repository;

  ResetPasswordUseCase(this.repository);

  Future<Either<Failure, void>> call(String email, {required String redirectTo}) async {
    return await repository.resetPassword(email, redirectTo: redirectTo);
  }
}
