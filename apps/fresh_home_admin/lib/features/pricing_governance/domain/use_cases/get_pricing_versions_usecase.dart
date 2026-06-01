import '../entities/pricing_version_entity.dart';
import '../repositories/pricing_governance_repository.dart';

class GetPricingVersionsUseCase {
  final PricingGovernanceRepository _repository;

  GetPricingVersionsUseCase(this._repository);

  Future<List<PricingVersionEntity>> call(String subServiceId) async {
    return await _repository.getPricingVersions(subServiceId);
  }
}
