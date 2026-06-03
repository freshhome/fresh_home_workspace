import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pricing_rule_model.dart';
import '../models/pricing_discount_model.dart';
import '../models/pricing_version_model.dart';

abstract class PricingGovernanceRemoteDataSource {
  Future<List<PricingRuleModel>> getRulesBySubService(String subServiceId);
  Future<void> upsertRule(PricingRuleModel rule);
  Future<void> toggleRuleActive(String ruleId, bool isActive);
  Future<List<PricingDiscountModel>> getDiscounts();
  Future<void> upsertDiscount(PricingDiscountModel discount);
  Future<void> toggleDiscountActive(String discountId, bool isActive);
  Future<void> deleteDiscount(String discountId);
  Future<List<PricingVersionModel>> getPricingVersions(String subServiceId);
  Future<List<Map<String, dynamic>>> getGovernanceAuditLogs(String subServiceId);
  Future<Map<String, dynamic>> replayBookingPricing(String bookingId);
  Future<Map<String, dynamic>> simulatePricingPipeline(String subServiceId, Map<String, dynamic> inputs, List<Map<String, dynamic>> options);
}

class PricingGovernanceRemoteDataSourceImpl implements PricingGovernanceRemoteDataSource {
  final SupabaseClient _client;

  PricingGovernanceRemoteDataSourceImpl({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<List<PricingRuleModel>> getRulesBySubService(String subServiceId) async {
    try {
      final response = await _client
          .from('pricing_rules')
          .select('*')
          .eq('sub_service_id', subServiceId)
          .order('priority', ascending: true);
      return (response as List).map((json) => PricingRuleModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pricing rules: $e');
    }
  }

  @override
  Future<void> upsertRule(PricingRuleModel rule) async {
    try {
      await _client.from('pricing_rules').upsert(rule.toJson());
    } catch (e) {
      throw Exception('Failed to upsert pricing rule: $e');
    }
  }

  @override
  Future<void> toggleRuleActive(String ruleId, bool isActive) async {
    try {
      await _client.from('pricing_rules').update({'is_active': isActive}).eq('id', ruleId);
    } catch (e) {
      throw Exception('Failed to toggle rule active status: $e');
    }
  }

  @override
  Future<List<PricingDiscountModel>> getDiscounts() async {
    try {
      final response = await _client
          .from('pricing_discounts')
          .select('*')
          .order('priority', ascending: true);
      return (response as List).map((json) => PricingDiscountModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pricing discounts: $e');
    }
  }

  @override
  Future<void> upsertDiscount(PricingDiscountModel discount) async {
    try {
      await _client.from('pricing_discounts').upsert(discount.toJson());
    } catch (e) {
      throw Exception('Failed to upsert pricing discount: $e');
    }
  }

  @override
  Future<void> toggleDiscountActive(String discountId, bool isActive) async {
    try {
      await _client.from('pricing_discounts').update({'is_active': isActive}).eq('id', discountId);
    } catch (e) {
      throw Exception('Failed to toggle discount active status: $e');
    }
  }

  @override
  Future<void> deleteDiscount(String discountId) async {
    try {
      await _client.from('pricing_discounts').delete().eq('id', discountId);
    } catch (e) {
      throw Exception('Failed to delete pricing discount: $e');
    }
  }

  @override
  Future<List<PricingVersionModel>> getPricingVersions(String subServiceId) async {
    try {
      final response = await _client
          .from('pricing_versions')
          .select('*')
          .eq('sub_service_id', subServiceId)
          .order('created_at', ascending: false);
      return (response as List).map((json) => PricingVersionModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get pricing versions: $e');
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getGovernanceAuditLogs(String subServiceId) async {
    try {
      final response = await _client
          .from('pricing_governance_audit')
          .select('*')
          .eq('sub_service_id', subServiceId)
          .order('created_at', ascending: false);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw Exception('Failed to get governance audit logs: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> replayBookingPricing(String bookingId) async {
    try {
      final response = await _client.rpc('replay_booking_pricing', params: {
        'p_booking_id': bookingId,
      });
      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      throw Exception('Failed to replay booking pricing: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> simulatePricingPipeline(String subServiceId, Map<String, dynamic> inputs, List<Map<String, dynamic>> options) async {
    try {
      final response = await _client.rpc('simulate_pricing_pipeline', params: {
        'p_service_id': subServiceId,
        'p_inputs': inputs,
        'p_options': options,
      });
      return Map<String, dynamic>.from(response ?? {});
    } catch (e) {
      throw Exception('Failed to simulate pricing pipeline: $e');
    }
  }
}
