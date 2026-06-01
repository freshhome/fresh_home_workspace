import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'pricing_method.g.dart';

@JsonEnum(alwaysCreate: true)
@HiveType(typeId: HiveTypeIds.pricingMethod)
enum PricingMethod {
  @JsonValue('per_square_meter')
  @HiveField(0)
  perSquareMeter,

  @JsonValue('per_linear_meter')
  @HiveField(1)
  perLinearMeter,

  @JsonValue('fixed')
  @HiveField(2)
  fixed,

  @JsonValue('per_issue')
  @HiveField(3)
  perIssue,

  @JsonValue('unknown')
  @HiveField(4)
  unknown,

  @JsonValue('inspection')
  @HiveField(5)
  inspection,
}
