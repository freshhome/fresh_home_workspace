import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/user/entities/user/user_profile.dart';
import 'package:shared/core/error/failures.dart';

abstract class UserRepository {
  Future<Either<Failure, void>> createUser({
    required UserProfile user,
  });

  Future<Either<Failure, UserProfile>> getUserById({required String uid});

  Future<Either<Failure, void>> updateUser({required UserProfile user});
}
