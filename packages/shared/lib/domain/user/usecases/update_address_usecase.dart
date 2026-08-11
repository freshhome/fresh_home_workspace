import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';
import 'package:shared/domain/user/validation/address_validator.dart';

class UpdateAddressUseCase {
  final AddressRepository repository;

  const UpdateAddressUseCase(this.repository);

  Future<Either<Failure, Address>> call(Address address) async {
    final validationResult = AddressValidator.validate(address);
    return validationResult.fold(
      (failure) => left(failure),
      (validAddress) => repository.updateAddress(validAddress),
    );
  }
}
