import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';
import 'package:shared/domain/user/validation/address_validator.dart';

class CreateAddressUseCase {
  final AddressRepository repository;

  const CreateAddressUseCase(this.repository);

  Future<Either<Failure, Address>> call(Address address) async {
    final validationResult = AddressValidator.validate(address);
    return validationResult.fold(
      (failure) => left(failure),
      (validAddress) => repository.createAddress(validAddress),
    );
  }
}

typedef AddAddressUseCase = CreateAddressUseCase;

