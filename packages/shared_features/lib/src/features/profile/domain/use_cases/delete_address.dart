import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../entities/user_with_profile.dart';
import '../repositories/profile_repository.dart';

class DeleteAddressUseCase {
  final ProfileRepository repository;

  DeleteAddressUseCase(this.repository);

  Future<Either<Failure, UserWithProfile>> call(int index) {
    return repository.deleteAddress(index: index);
  }
}
