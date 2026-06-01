import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';

abstract class SplashRepositories {
  Future<Either<Failure, bool>> isUserLoggedIn();
}
