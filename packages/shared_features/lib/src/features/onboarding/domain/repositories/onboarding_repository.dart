import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';

abstract class OnboardingRepository {
  Future<Either<Failure, bool>> isOnboardingCompleted();
  Future<Either<Failure, Unit>> setOnboardingCompleted();
}
