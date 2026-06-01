import '../repositories/pricing_governance_repository.dart';

class TogglePricingRuleUseCase {
  final PricingGovernanceRepository _repository;

  TogglePricingRuleUseCase(this._repository);

  Future<void> call(String ruleId, bool isActive) async {
    await _repository.toggleRuleActive(ruleId, isActive);
  }
}
