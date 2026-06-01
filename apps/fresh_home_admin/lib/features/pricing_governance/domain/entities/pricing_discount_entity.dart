import 'package:equatable/equatable.dart';

class PricingDiscountEntity extends Equatable {
  final String id;
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

  @override
  List<Object?> get props => [
    id,
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
