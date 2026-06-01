import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import '../entities/user_with_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserWithProfile>> loadProfile();
  Future<Either<Failure, UserWithProfile>> updateUserName({required String firstName, required String lastName});
  Future<Either<Failure, UserWithProfile>> updateProfile({String? firstName, String? lastName, String? gender, String? avatarUrl});
  Future<Either<Failure, UserWithProfile>> updatePhoneNumbers({required List<Phone> phoneNumbers});
  Future<Either<Failure, UserWithProfile>> addAddress({required Address address});
  Future<Either<Failure, UserWithProfile>> updateAddress({required int index, required Address address});
  Future<Either<Failure, UserWithProfile>> deleteAddress({required int index});
}
