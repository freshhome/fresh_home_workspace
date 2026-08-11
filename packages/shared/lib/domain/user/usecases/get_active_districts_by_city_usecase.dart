import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/district.dart';
import 'package:shared/domain/user/repositories/geographic_reference_repository.dart';

/// UseCase fetching active Geographic Districts by City ID.
class GetActiveDistrictsByCityUseCase {
  final GeographicReferenceRepository repository;

  GetActiveDistrictsByCityUseCase(this.repository);

  Future<Either<Failure, List<District>>> call(int cityId) {
    return repository.getDistrictsByCity(cityId);
  }
}
