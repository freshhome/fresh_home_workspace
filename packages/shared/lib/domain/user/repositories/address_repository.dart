import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';

/// Repository Contract for Address Domain Entity.
abstract class AddressRepository {
  /// Retrieves all active (non-deleted) addresses for a given user.
  Future<Either<Failure, List<Address>>> getAddresses(String userId);

  /// Retrieves a specific address by ID.
  Future<Either<Failure, Address>> getAddressById(String addressId);

  /// Retrieves the active primary address for a user, if one exists.
  Future<Either<Failure, Address?>> getPrimaryAddress(String userId);

  /// Creates a new address for a user. Validates domain rules before saving.
  Future<Either<Failure, Address>> createAddress(Address address);

  /// Updates an existing address.
  Future<Either<Failure, Address>> updateAddress(Address address);

  /// Deletes an address. Executes Hard Delete if unused, or Soft Delete if referenced in bookings.
  Future<Either<Failure, void>> deleteAddress(String addressId);

  /// Sets an address as the user's primary address, unsetting any previous primary address.
  Future<Either<Failure, void>> setPrimaryAddress({
    required String userId,
    required String addressId,
  });
}
