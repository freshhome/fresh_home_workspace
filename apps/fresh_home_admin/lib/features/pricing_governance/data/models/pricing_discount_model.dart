import '../../domain/entities/pricing_discount_entity.dart';

class PricingDiscountModel extends PricingDiscountEntity {
  const PricingDiscountModel({
    required super.id,
    required super.name,
    required super.code,
    required super.campaignType,
    required super.discountType,
    required super.discountValue,
    required super.isStackable,
    required super.priority,
    super.startDate,
    super.endDate,
    super.usageLimit,
    required super.usageCount,
    required super.isActive,
  });

  factory PricingDiscountModel.fromJson(Map<String, dynamic> json) {
    return PricingDiscountModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '', // اسم الحملة
      code: json['code'] as String? ?? '',
      campaignType: json['type'] as String? ?? 'coupon', // DB column: type
      discountType: json['value_type'] as String? ?? 'fixed', // DB column: value_type
      discountValue: (json['value'] as num?)?.toDouble() ?? 0.0, // DB column: value
      isStackable: json['stackable'] as bool? ?? false, // DB column: stackable
      priority: json['priority'] as int? ?? 1,
      startDate: json['start_date'] != null ? DateTime.parse(json['start_date'] as String) : null,
      endDate: json['end_date'] != null ? DateTime.parse(json['end_date'] as String) : null,
      usageLimit: json['usage_limit'] as int?,
      usageCount: json['usage_count'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'type': campaignType, // DB column: type
      'value_type': discountType, // DB column: value_type
      'value': discountValue, // DB column: value
      'stackable': isStackable, // DB column: stackable
      'priority': priority,
      'start_date': startDate?.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'usage_limit': usageLimit,
      'usage_count': usageCount,
      'is_active': isActive,
    };
  }
}
