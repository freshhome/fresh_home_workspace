import '../../domain/entities/technician_capacity_entry.dart';

class TechnicianCapacityModel extends TechnicianCapacityEntry {
  const TechnicianCapacityModel({
    required super.technicianId,
    required super.technicianName,
    super.mainServiceId,
    required super.workload,
    required super.capacity,
    required super.status,
    required super.utilizationPercentage,
  });

  factory TechnicianCapacityModel.fromJson(Map<String, dynamic> json) {
    return TechnicianCapacityModel(
      technicianId: json['technician_id'] as String,
      technicianName: json['technician_name'] as String? ?? 'Unknown',
      mainServiceId: json['main_service_id'] as String?,
      workload: json['workload'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      status: json['status'] as String? ?? 'idle',
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  TechnicianCapacityEntry toEntity() {
    return TechnicianCapacityEntry(
      technicianId: technicianId,
      technicianName: technicianName,
      mainServiceId: mainServiceId,
      workload: workload,
      capacity: capacity,
      status: status,
      utilizationPercentage: utilizationPercentage,
    );
  }
}
