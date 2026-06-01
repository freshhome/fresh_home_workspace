import '../../domain/entities/pricing_version_entity.dart';

class PricingVersionModel extends PricingVersionEntity {
  const PricingVersionModel({
    required super.id,
    required super.subServiceId,
    required super.snapshot,
    required super.createdAt,
    required super.isActive,
  });

  factory PricingVersionModel.fromJson(Map<String, dynamic> json) {
    return PricingVersionModel(
      id: json['id'] as String? ?? '',
      subServiceId: json['sub_service_id'] as String? ?? '',
      snapshot: Map<String, dynamic>.from(json['snapshot'] as Map? ?? {}),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_service_id': subServiceId,
      'snapshot': snapshot,
      'created_at': createdAt.toIso8601String(),
      'is_active': isActive,
    };
  }
}
