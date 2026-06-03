import '../repositories/pricing_governance_repository.dart';

class TogglePricingDiscountUseCase {
  final PricingGovernanceRepository _repository;

  TogglePricingDiscountUseCase(this._repository);

  Future<void> call(String discountId, bool isActive) async {
    await _repository.toggleDiscountActive(discountId, isActive);
  }
}
