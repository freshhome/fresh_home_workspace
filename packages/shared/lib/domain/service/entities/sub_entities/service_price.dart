import '../../enums/pricing_method.dart';
import '../../../booking/entities/booking/sub_entities/dynamic_field.dart';

class PriceOptionEntity {
  final String? key;
  final num? value;
  final Map<String, String>? label;

  const PriceOptionEntity({this.key, this.value, this.label});
}

class PriceEntity {
  final PricingMethod type;
  final num value;
  final String unit;
  final List<PriceOptionEntity> options;
  final List<DynamicFieldEntity> fields;
  /// Phase 3: Optional formula string, e.g. `({area} * {price_per_sqm}) + {setup_fee}`.
  /// When non-null, the backend formula engine evaluates this instead of hardcoded enum logic.
  final String? basePriceFormula;
  final num? minPrice;

  const PriceEntity({
    required this.type,
    required this.value,
    required this.unit,
    required this.options,
    this.fields = const [],
    this.basePriceFormula,
    this.minPrice,
  });
}
