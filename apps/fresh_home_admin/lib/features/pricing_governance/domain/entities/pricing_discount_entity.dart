import 'package:equatable/equatable.dart';

class PricingDiscountEntity extends Equatable {
  final String id;
  final String? subServiceId;
  final String name;
  final String code;
  final String campaignType;
  final String discountType;
  final double discountValue;
  final bool isStackable;
  final int priority;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? usageLimit;
  final int usageCount;
  final bool isActive;

  const PricingDiscountEntity({
    required this.id,
    this.subServiceId,
    required this.name,
    required this.code,
    required this.campaignType,
    required this.discountType,
    required this.discountValue,
    required this.isStackable,
    required this.priority,
    this.startDate,
    this.endDate,
    this.usageLimit,
    required this.usageCount,
    required this.isActive,
  });

  PricingDiscountEntity copyWith({
    String? id,
    String? subServiceId,
    String? name,
    String? code,
    String? campaignType,
    String? discountType,
    double? discountValue,
    bool? isStackable,
    int? priority,
    DateTime? startDate,
    DateTime? endDate,
    int? usageLimit,
    int? usageCount,
    bool? isActive,
  }) {
    return PricingDiscountEntity(
      id: id ?? this.id,
      subServiceId: subServiceId ?? this.subServiceId,
      name: name ?? this.name,
      code: code ?? this.code,
      campaignType: campaignType ?? this.campaignType,
      discountType: discountType ?? this.discountType,
      discountValue: discountValue ?? this.discountValue,
      isStackable: isStackable ?? this.isStackable,
      priority: priority ?? this.priority,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      usageLimit: usageLimit ?? this.usageLimit,
      usageCount: usageCount ?? this.usageCount,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
    id,
    subServiceId,
    name,
    code,
    campaignType,
    discountType,
    discountValue,
    isStackable,
    priority,
    startDate,
    endDate,
    usageLimit,
    usageCount,
    isActive,
  ];
}

