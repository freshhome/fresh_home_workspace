import '../entities/pricing_rule_entity.dart';
import '../entities/pricing_discount_entity.dart';
import '../entities/pricing_version_entity.dart';

abstract class PricingGovernanceRepository {
  Future<List<PricingRuleEntity>> getRulesBySubService(String subServiceId);
  Future<void> upsertRule(PricingRuleEntity rule);
  Future<void> toggleRuleActive(String ruleId, bool isActive);
  Future<List<PricingDiscountEntity>> getDiscounts();
  Future<void> upsertDiscount(PricingDiscountEntity discount);
  Future<List<PricingVersionEntity>> getPricingVersions(String subServiceId);
  Future<List<Map<String, dynamic>>> getGovernanceAuditLogs(String subServiceId);
  Future<Map<String, dynamic>> replayBookingPricing(String bookingId);
  Future<Map<String, dynamic>> simulatePricingPipeline(String subServiceId, Map<String, dynamic> inputs, List<Map<String, dynamic>> options);
}
