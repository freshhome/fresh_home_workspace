import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/user/datasources/address_remote_datasource.dart';
import 'package:shared/data/user/models/address_model.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/repositories/address_repository.dart';

class AddressRepositoryImpl implements AddressRepository {
  final AddressRemoteDataSource remoteDataSource;

  AddressRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Address>>> getAddresses(String userId) async {
    try {
      final models = await remoteDataSource.getAddresses(userId);
      return right(models.map((m) => m.toEntity()).toList());
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address>> getAddressById(String addressId) async {
    try {
      final model = await remoteDataSource.getAddressById(addressId);
      return right(model.toEntity());
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address?>> getPrimaryAddress(String userId) async {
    try {
      final model = await remoteDataSource.getPrimaryAddress(userId);
      return right(model?.toEntity());
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address>> createAddress(Address address) async {
    try {
      final model = AddressModel.fromEntity(address);
      final createdModel = await remoteDataSource.createAddress(model);
      return right(createdModel.toEntity());
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Address>> updateAddress(Address address) async {
    try {
      final model = AddressModel.fromEntity(address);
      final updatedModel = await remoteDataSource.updateAddress(model);
      return right(updatedModel.toEntity());
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAddress(String addressId) async {
    try {
      await remoteDataSource.deleteAddress(addressId);
      return right(null);
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> setPrimaryAddress({
    required String userId,
    required String addressId,
  }) async {
    try {
      await remoteDataSource.setPrimaryAddress(userId: userId, addressId: addressId);
      return right(null);
    } on ServerFailure catch (e) {
      return left(e);
    } catch (e) {
      return left(ServerFailure(message: e.toString()));
    }
  }
}
