import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';

class GetUserAddressesUseCase {
  final AddressRepository repository;

  const GetUserAddressesUseCase(this.repository);

  Future<Either<Failure, List<Address>>> call(String userId) {
    if (userId.trim().isEmpty) {
      return Future.value(left(const ValidationFailure(message: 'User ID cannot be empty')));
    }
    return repository.getAddresses(userId);
  }
}
