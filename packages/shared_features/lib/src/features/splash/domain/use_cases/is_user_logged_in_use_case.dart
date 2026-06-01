import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared_features/src/features/splash/domain/repositories/splash_repositories.dart';

class IsUserLoggedInUseCase {
  final SplashRepositories splashRepositories;

  IsUserLoggedInUseCase(this.splashRepositories);

  Future<Either<Failure, bool>> call() async {
    return await splashRepositories.isUserLoggedIn();
  }
}
