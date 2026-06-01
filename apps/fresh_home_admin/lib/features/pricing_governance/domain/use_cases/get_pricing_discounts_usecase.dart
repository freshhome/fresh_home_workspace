import '../entities/pricing_discount_entity.dart';
import '../repositories/pricing_governance_repository.dart';

class GetPricingDiscountsUseCase {
  final PricingGovernanceRepository _repository;

  GetPricingDiscountsUseCase(this._repository);

  Future<List<PricingDiscountEntity>> call() async {
    return await _repository.getDiscounts();
  }
}
