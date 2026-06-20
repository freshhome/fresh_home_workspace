import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../repositories/profile_repository.dart';

class UpdateAddressUseCase {
  final ProfileRepository repository;

  UpdateAddressUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(int index, Address address) {
    return repository.updateAddress(index: index, address: address);
  }
}
