import '../entities/pricing_rule_entity.dart';
import '../repositories/pricing_governance_repository.dart';

class GetPricingRulesUseCase {
  final PricingGovernanceRepository _repository;

  GetPricingRulesUseCase(this._repository);

  Future<List<PricingRuleEntity>> call(String subServiceId) async {
    return await _repository.getRulesBySubService(subServiceId);
  }
}
