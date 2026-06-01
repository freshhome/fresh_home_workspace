import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../repositories/onboarding_repository.dart';

class SetOnboardingCompletedUseCase {
  final OnboardingRepository repository;

  SetOnboardingCompletedUseCase(this.repository);

  Future<Either<Failure, Unit>> call() async {
    return await repository.setOnboardingCompleted();
  }
}
