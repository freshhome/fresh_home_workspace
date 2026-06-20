import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../repositories/profile_repository.dart';

class DeleteAddressUseCase {
  final ProfileRepository repository;

  DeleteAddressUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(int index) {
    return repository.deleteAddress(index: index);
  }
}
