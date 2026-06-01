import '../../../domain/technician/entities/technician_pool_status.dart';

class TechnicianPoolStatusModel extends TechnicianPoolStatus {
  const TechnicianPoolStatusModel({
    required super.poolId,
    required super.title,
    required super.maxCapacity,
    required super.currentLoad,
    required super.isBlocked,
    super.overrideCapacity,
    required super.isOverride,
    super.slotMask,
    super.services,
  });

  factory TechnicianPoolStatusModel.fromJson(Map<String, dynamic> json) {
    return TechnicianPoolStatusModel(
      poolId: json['pool_id'] as String,
      title: json['pool_title'] as String,
      maxCapacity: (json['max_capacity'] ?? 0).toInt(),
      currentLoad: (json['current_load'] ?? 0).toInt(),
      isBlocked: json['is_blocked'] as bool,
      overrideCapacity: json['override_capacity'] != null 
          ? (json['override_capacity'] as num).toInt() 
          : null,
      isOverride: json['is_override'] as bool,
      slotMask: json['slot_mask'] as String?,
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
