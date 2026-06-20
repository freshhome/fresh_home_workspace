import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';
import 'package:shared/domain/user/entities/user/phone.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> loadProfile();
  Future<Either<Failure, UserProfile>> updateUserName({required String firstName, required String lastName});
  Future<Either<Failure, UserProfile>> updateProfile({String? firstName, String? lastName, String? gender, String? avatarUrl});
  Future<Either<Failure, UserProfile>> updatePhoneNumbers({required List<Phone> phoneNumbers});
  Future<Either<Failure, UserProfile>> addAddress({required Address address});
  Future<Either<Failure, UserProfile>> updateAddress({required int index, required Address address});
  Future<Either<Failure, UserProfile>> deleteAddress({required int index});
}
