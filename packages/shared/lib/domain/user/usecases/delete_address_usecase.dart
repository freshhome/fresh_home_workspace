import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';

class DeleteAddressUseCase {
  final AddressRepository repository;

  const DeleteAddressUseCase(this.repository);

  Future<Either<Failure, void>> call(String addressId) {
    if (addressId.trim().isEmpty) {
      return Future.value(left(const ValidationFailure(message: 'Address ID cannot be empty')));
    }
    return repository.deleteAddress(addressId);
  }
}
