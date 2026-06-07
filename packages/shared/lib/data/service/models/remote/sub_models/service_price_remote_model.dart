import 'package:json_annotation/json_annotation.dart';
import 'package:shared/domain/service/enums/pricing_method.dart';

part 'service_price_remote_model.g.dart';

@JsonSerializable()
class PriceOptionRemoteModel {
  final String? key;
  final double? value;

  const PriceOptionRemoteModel({
    this.key,
    this.value,
  });

  factory PriceOptionRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$PriceOptionRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceOptionRemoteModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class PriceRemoteModel {
  final PricingMethod type;
  @JsonKey(defaultValue: 0.0)
  final double value;
  @JsonKey(defaultValue: '')
  final String unit;
  @JsonKey(defaultValue: [])
  final List<PriceOptionRemoteModel> options;
  @JsonKey(defaultValue: [])
  final List<DynamicFieldRemoteModel> fields;
  /// Phase 3: Optional formula for dynamic pricing evaluation.
  @JsonKey(name: 'base_price_formula', includeIfNull: false)
  final String? basePriceFormula;
  @JsonKey(name: 'min_price', includeIfNull: false)
  final double? minPrice;

  const PriceRemoteModel({
    required this.type,
    this.value = 0.0,
    this.unit = '',
    this.options = const [],
    this.fields = const [],
    this.basePriceFormula,
    this.minPrice,
  });

  factory PriceRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$PriceRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$PriceRemoteModelToJson(this);
}

class DynamicFieldRemoteModel {
  final String id;
  final String type;
  final Map<String, String> label;
  final bool required;
  final double? min;
  final String? unit;
  @JsonKey(name: 'price_modifier')
  final double? priceModifier;
  final List<DropdownOptionRemoteModel>? options;
  final Map<String, String>? description;
  final String? icon;
  @JsonKey(name: 'display_type')
  final String? displayType;

  const DynamicFieldRemoteModel({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.min,
    this.unit,
    this.priceModifier,
    this.options,
    this.description,
    this.icon,
    this.displayType,
  });

  factory DynamicFieldRemoteModel.fromJson(Map<String, dynamic> json) {
    return DynamicFieldRemoteModel(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? 'number',
      label: Map<String, String>.from(json['label'] as Map? ?? {}),
      required: json['required'] as bool? ?? false,
      min: (json['min'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      priceModifier: (json['price_modifier'] as num?)?.toDouble(),
      options: (json['options'] as List?)
          ?.map((e) => DropdownOptionRemoteModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      description: json['description'] != null
          ? Map<String, String>.from(json['description'] as Map)
          : null,
      icon: json['icon'] as String?,
      displayType: json['display_type'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label': label,
      'required': required,
      'min': min,
      'unit': unit,
      'price_modifier': priceModifier,
      'options': options?.map((e) => e.toJson()).toList(),
      'description': description,
      'icon': icon,
      'display_type': displayType,
    };
  }
}

class DropdownOptionRemoteModel {
  final String id;
  final Map<String, String> label;

  const DropdownOptionRemoteModel({
    required this.id,
    required this.label,
  });

  factory DropdownOptionRemoteModel.fromJson(Map<String, dynamic> json) {
    return DropdownOptionRemoteModel(
      id: json['id'] as String? ?? '',
      label: Map<String, String>.from(json['label'] as Map? ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }
}
