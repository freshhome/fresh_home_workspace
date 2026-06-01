import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/user_with_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateUserNameUseCase {
  final ProfileRepository repository;

  UpdateUserNameUseCase(this.repository);

  Future<Either<Failure, UserWithProfile>> call(String firstName, String lastName) {
    return repository.updateUserName(firstName: firstName, lastName: lastName);
  }
}
