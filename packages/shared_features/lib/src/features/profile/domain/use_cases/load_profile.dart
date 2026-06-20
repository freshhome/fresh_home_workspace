import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../repositories/profile_repository.dart';

class LoadProfileUseCase {
  final ProfileRepository repository;
  LoadProfileUseCase(this.repository);
  Future<Either<Failure, UserProfile>> call() => repository.loadProfile();
}
