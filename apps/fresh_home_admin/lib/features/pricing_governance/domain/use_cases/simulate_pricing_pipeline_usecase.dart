import '../repositories/pricing_governance_repository.dart';

class SimulatePricingPipelineUseCase {
  final PricingGovernanceRepository _repository;

  SimulatePricingPipelineUseCase(this._repository);

  Future<Map<String, dynamic>> call(String subServiceId, Map<String, dynamic> inputs, List<Map<String, dynamic>> options) async {
    return await _repository.simulatePricingPipeline(subServiceId, inputs, options);
  }
}
