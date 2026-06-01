import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/user_with_profile.dart';
import '../repositories/profile_repository.dart';

class LoadProfileUseCase {
  final ProfileRepository repository;
  LoadProfileUseCase(this.repository);
  Future<Either<Failure, UserWithProfile>> call() => repository.loadProfile();
}
