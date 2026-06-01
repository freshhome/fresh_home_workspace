import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/error_mapper.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/core/error/failures.dart';

import 'package:shared_features/src/features/splash/data/data_sources/splash_data_sources.dart';
import 'package:shared_features/src/features/splash/domain/repositories/splash_repositories.dart';

class SplashRepositoriesImpl implements SplashRepositories {
  SplashDataSources splashDataSources;

  SplashRepositoriesImpl({required this.splashDataSources});
  @override
  Future<Either<Failure, bool>> isUserLoggedIn() async {
    try {
      final result = await splashDataSources.isUserLoggedIn();

      return Right(result);
    } on AppException catch (e) {
      return Left(ErrorMapper.mapExceptionToFailure(e));
    } catch (e) {
      return Left(
        UnknownFailure(message: e.toString(), code: 'unexpected_error'),
      );
    }
  }
}
