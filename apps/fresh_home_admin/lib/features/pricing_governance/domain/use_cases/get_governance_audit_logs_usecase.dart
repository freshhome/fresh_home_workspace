import '../repositories/pricing_governance_repository.dart';

class GetGovernanceAuditLogsUseCase {
  final PricingGovernanceRepository _repository;

  GetGovernanceAuditLogsUseCase(this._repository);

  Future<List<Map<String, dynamic>>> call(String subServiceId) async {
    return await _repository.getGovernanceAuditLogs(subServiceId);
  }
}
