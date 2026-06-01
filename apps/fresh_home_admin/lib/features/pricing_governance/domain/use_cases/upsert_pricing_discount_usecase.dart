import '../entities/pricing_discount_entity.dart';
import '../repositories/pricing_governance_repository.dart';

class UpsertPricingDiscountUseCase {
  final PricingGovernanceRepository _repository;

  UpsertPricingDiscountUseCase(this._repository);

  Future<void> call(PricingDiscountEntity discount) async {
    await _repository.upsertDiscount(discount);
  }
}
