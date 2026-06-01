import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';

part 'service_price_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.priceOption)
class PriceOptionHiveModel extends HiveObject {
  @override
  @HiveField(0)
  final String? key;
  @HiveField(1)
  final double? value;

  PriceOptionHiveModel({this.key, this.value});
}

@HiveType(typeId: HiveTypeIds.price)
class PriceHiveModel extends HiveObject {
  @HiveField(0)
  final PricingMethod type;
  @HiveField(1)
  final double value;
  @HiveField(2)
  final String unit;
  @HiveField(3)
  final List<PriceOptionHiveModel> options;
  @HiveField(4)
  final List<dynamic>? fields;
  /// Phase 3: Optional formula string for formula-based pricing.
  @HiveField(5)
  final String? basePriceFormula;
  @HiveField(6)
  final double? minPrice;

  PriceHiveModel({
    required this.type,
    required this.value,
    required this.unit,
    required this.options,
    this.fields = const [],
    this.basePriceFormula,
    this.minPrice,
  });
}
