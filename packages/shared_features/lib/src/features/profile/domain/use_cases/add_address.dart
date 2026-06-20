import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import '../repositories/profile_repository.dart';

class AddAddressUseCase {
  final ProfileRepository repository;

  AddAddressUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call(Address address) {
    return repository.addAddress(address: address);
  }
}
