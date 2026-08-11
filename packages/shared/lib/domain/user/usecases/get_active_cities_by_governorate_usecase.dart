import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/city.dart';
import 'package:shared/domain/user/repositories/geographic_reference_repository.dart';

/// UseCase fetching active Geographic Cities by Governorate ID.
class GetActiveCitiesByGovernorateUseCase {
  final GeographicReferenceRepository repository;

  GetActiveCitiesByGovernorateUseCase(this.repository);

  Future<Either<Failure, List<City>>> call(int governorateId) {
    return repository.getCitiesByGovernorate(governorateId);
  }
}
