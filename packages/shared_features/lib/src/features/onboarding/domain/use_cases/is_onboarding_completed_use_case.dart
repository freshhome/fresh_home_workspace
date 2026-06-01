import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../repositories/onboarding_repository.dart';

class IsOnboardingCompletedUseCase {
  final OnboardingRepository repository;

  IsOnboardingCompletedUseCase(this.repository);

  Future<Either<Failure, bool>> call() async {
    return await repository.isOnboardingCompleted();
  }
}
