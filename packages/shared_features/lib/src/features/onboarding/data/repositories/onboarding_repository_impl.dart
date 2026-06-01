import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_datasource.dart';

class OnboardingRepositoryImpl implements OnboardingRepository {
  final OnboardingLocalDataSource localDataSource;

  OnboardingRepositoryImpl(this.localDataSource);

  @override
  Future<Either<Failure, bool>> isOnboardingCompleted() async {
    try {
      final result = await localDataSource.isOnboardingCompleted();
      return Right(result);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> setOnboardingCompleted() async {
    try {
      await localDataSource.setOnboardingCompleted();
      return const Right(unit);
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}
