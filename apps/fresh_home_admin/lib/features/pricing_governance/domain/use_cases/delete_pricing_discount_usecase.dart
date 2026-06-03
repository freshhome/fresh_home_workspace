import '../repositories/pricing_governance_repository.dart';

class DeletePricingDiscountUseCase {
  final PricingGovernanceRepository _repository;

  DeletePricingDiscountUseCase(this._repository);

  Future<void> call(String discountId) async {
    await _repository.deleteDiscount(discountId);
  }
}
