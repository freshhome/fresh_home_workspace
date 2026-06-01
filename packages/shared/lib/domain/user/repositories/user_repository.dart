import 'package:fpdart/fpdart.dart';

import 'package:shared/domain/user/entities/user/user.dart';
import 'package:shared/core/error/failures.dart';

abstract class UserRepository {
  // ! تسجيل المستخدم
  Future<Either<Failure, void>> createUser({
    required User user,
  });

  // ! الحصول على المستخدم بـ uid
  Future<Either<Failure, User>> getUserById({required String uid});

  // ! تحديث المستخدم
  Future<Either<Failure, void>> updateUser({required User user});
}
