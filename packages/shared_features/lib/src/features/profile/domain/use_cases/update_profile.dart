import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/user_with_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateProfileUseCase {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  Future<Either<Failure, UserWithProfile>> call({
    String? firstName,
    String? lastName,
    String? gender,
    String? avatarUrl,
  }) {
    return repository.updateProfile(
      firstName: firstName,
      lastName: lastName,
      gender: gender,
      avatarUrl: avatarUrl,
    );
  }
}
