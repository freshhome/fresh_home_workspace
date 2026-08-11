import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';

class SetPrimaryAddressUseCase {
  final AddressRepository repository;

  const SetPrimaryAddressUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String userId,
    required String addressId,
  }) {
    if (userId.trim().isEmpty || addressId.trim().isEmpty) {
      return Future.value(left(const ValidationFailure(message: 'User ID and Address ID are required')));
    }
    return repository.setPrimaryAddress(userId: userId, addressId: addressId);
  }
}
