// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_price_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PriceOptionRemoteModel _$PriceOptionRemoteModelFromJson(
        Map<String, dynamic> json) =>
    PriceOptionRemoteModel(
      key: json['key'] as String?,
      value: (json['value'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PriceOptionRemoteModelToJson(
        PriceOptionRemoteModel instance) =>
    <String, dynamic>{
      'key': instance.key,
      'value': instance.value,
    };

PriceRemoteModel _$PriceRemoteModelFromJson(Map<String, dynamic> json) =>
    PriceRemoteModel(
      type: $enumDecode(_$PricingMethodEnumMap, json['type']),
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)
              ?.map((e) =>
                  PriceOptionRemoteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      fields: (json['fields'] as List<dynamic>?)
              ?.map((e) =>
                  DynamicFieldRemoteModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      basePriceFormula: json['base_price_formula'] as String?,
      minPrice: (json['min_price'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$PriceRemoteModelToJson(PriceRemoteModel instance) {
  final val = <String, dynamic>{
    'type': _$PricingMethodEnumMap[instance.type]!,
    'value': instance.value,
    'unit': instance.unit,
    'options': instance.options.map((e) => e.toJson()).toList(),
    'fields': instance.fields.map((e) => e.toJson()).toList(),
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('base_price_formula', instance.basePriceFormula);
  writeNotNull('min_price', instance.minPrice);
  return val;
}

const _$PricingMethodEnumMap = {
  PricingMethod.perSquareMeter: 'per_square_meter',
  PricingMethod.perLinearMeter: 'per_linear_meter',
  PricingMethod.fixed: 'fixed',
  PricingMethod.perIssue: 'per_issue',
  PricingMethod.unknown: 'unknown',
  PricingMethod.inspection: 'inspection',
};
