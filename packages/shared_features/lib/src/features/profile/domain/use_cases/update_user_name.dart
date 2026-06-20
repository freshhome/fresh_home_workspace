import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateUserNameUseCase {
  final ProfileRepository repository;

  UpdateUserNameUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(String firstName, String lastName) {
    return repository.updateUserName(firstName: firstName, lastName: lastName);
  }
}
