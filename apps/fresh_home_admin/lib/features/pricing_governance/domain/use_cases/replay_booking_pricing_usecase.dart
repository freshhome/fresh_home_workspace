import '../repositories/pricing_governance_repository.dart';

class ReplayBookingPricingUseCase {
  final PricingGovernanceRepository _repository;

  ReplayBookingPricingUseCase(this._repository);

  Future<Map<String, dynamic>> call(String bookingId) async {
    return await _repository.replayBookingPricing(bookingId);
  }
}
