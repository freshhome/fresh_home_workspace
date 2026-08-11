import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/governorate.dart';
import 'package:shared/domain/user/repositories/geographic_reference_repository.dart';

/// UseCase fetching active Geographic Governorates.
class GetActiveGovernoratesUseCase {
  final GeographicReferenceRepository repository;

  GetActiveGovernoratesUseCase(this.repository);

  Future<Either<Failure, List<Governorate>>> call() {
    return repository.getGovernorates();
  }
}
