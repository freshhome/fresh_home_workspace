import '../../domain/entities/pricing_rule_entity.dart';
import '../../domain/entities/pricing_discount_entity.dart';
import '../../domain/entities/pricing_version_entity.dart';
import '../../domain/repositories/pricing_governance_repository.dart';
import '../data_sources/pricing_governance_remote_data_source.dart';
import '../models/pricing_rule_model.dart';
import '../models/pricing_discount_model.dart';

class PricingGovernanceRepositoryImpl implements PricingGovernanceRepository {
  final PricingGovernanceRemoteDataSource _remoteDataSource;

  PricingGovernanceRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<PricingRuleEntity>> getRulesBySubService(String subServiceId) async {
    return await _remoteDataSource.getRulesBySubService(subServiceId);
  }

  @override
  Future<void> upsertRule(PricingRuleEntity rule) async {
    final model = PricingRuleModel(
      id: rule.id,
      subServiceId: rule.subServiceId,
      ruleName: rule.ruleName,
      conditionAst: rule.conditionAst,
      actionType: rule.actionType,
      actionValue: rule.actionValue,
      actionTarget: rule.actionTarget,
      priority: rule.priority,
      isActive: rule.isActive,
    );
    await _remoteDataSource.upsertRule(model);
  }

  @override
  Future<void> toggleRuleActive(String ruleId, bool isActive) async {
    await _remoteDataSource.toggleRuleActive(ruleId, isActive);
  }

  @override
  Future<List<PricingDiscountEntity>> getDiscounts() async {
    return await _remoteDataSource.getDiscounts();
  }

  @override
  Future<void> upsertDiscount(PricingDiscountEntity discount) async {
    final model = PricingDiscountModel(
      id: discount.id,
      name: discount.name,
      code: discount.code,
      campaignType: discount.campaignType,
      discountType: discount.discountType,
      discountValue: discount.discountValue,
      isStackable: discount.isStackable,
      priority: discount.priority,
      startDate: discount.startDate,
      endDate: discount.endDate,
      usageLimit: discount.usageLimit,
      usageCount: discount.usageCount,
      isActive: discount.isActive,
    );
    await _remoteDataSource.upsertDiscount(model);
  }

  @override
  Future<List<PricingVersionEntity>> getPricingVersions(String subServiceId) async {
    return await _remoteDataSource.getPricingVersions(subServiceId);
  }

  @override
  Future<List<Map<String, dynamic>>> getGovernanceAuditLogs(String subServiceId) async {
    return await _remoteDataSource.getGovernanceAuditLogs(subServiceId);
  }

  @override
  Future<Map<String, dynamic>> replayBookingPricing(String bookingId) async {
    return await _remoteDataSource.replayBookingPricing(bookingId);
  }

  @override
  Future<Map<String, dynamic>> simulatePricingPipeline(String subServiceId, Map<String, dynamic> inputs, List<Map<String, dynamic>> options) async {
    return await _remoteDataSource.simulatePricingPipeline(subServiceId, inputs, options);
  }
}
