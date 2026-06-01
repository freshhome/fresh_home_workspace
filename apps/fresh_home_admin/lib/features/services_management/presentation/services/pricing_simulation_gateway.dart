import 'package:supabase_flutter/supabase_flutter.dart';

class PricingSimulationResult {
  final double basePrice;
  final double subtotal;
  final double extraFees;
  final double discount;
  final double total;
  final List<dynamic> executionTrace;

  PricingSimulationResult({
    required this.basePrice,
    required this.subtotal,
    required this.extraFees,
    required this.discount,
    required this.total,
    required this.executionTrace,
  });

  factory PricingSimulationResult.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'] as Map<String, dynamic>? ?? {};
    return PricingSimulationResult(
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      subtotal: (metadata['subtotal'] as num?)?.toDouble() ?? 0.0,
      extraFees: (json['extraFees'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      executionTrace: metadata['execution_trace'] as List<dynamic>? ?? [],
    );
  }
}

class PricingSimulationGateway {
  final SupabaseClient _client;

  PricingSimulationGateway({SupabaseClient? client}) 
      : _client = client ?? Supabase.instance.client;

  Future<PricingSimulationResult> simulatePricing({
    required String subServiceId,
    required Map<String, dynamic> priceConfig,
    required Map<String, dynamic> pricingInputs,
    List<dynamic> rules = const [],
    List<dynamic> discounts = const [],
  }) async {
    try {
      final response = await _client.rpc(
        'simulate_pricing_pipeline',
        params: {
          'p_sub_service_id': subServiceId,
          'p_price_config': priceConfig,
          'p_rules': rules,
          'p_discounts': discounts,
          'p_pricing_inputs': pricingInputs,
        },
      );

      if (response == null) {
        throw Exception('Server returned null simulation response');
      }

      return PricingSimulationResult.fromJson(Map<String, dynamic>.from(response));
    } catch (e) {
      throw Exception('Pricing Simulation RPC failed: $e');
    }
  }
}
