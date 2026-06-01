import '../entities/pricing_rule_entity.dart';
import '../repositories/pricing_governance_repository.dart';

class UpsertPricingRuleUseCase {
  final PricingGovernanceRepository _repository;

  UpsertPricingRuleUseCase(this._repository);

  Future<void> call(PricingRuleEntity rule) async {
    await _repository.upsertRule(rule);
  }
}
