import '../../domain/entities/fleet_dashboard_entry.dart';

class FleetDashboardModel extends FleetDashboardEntry {
  const FleetDashboardModel({
    required super.targetDate,
    required super.totalCapacity,
    required super.totalBooked,
    required super.availableCapacity,
    required super.utilizationPercentage,
  });

  factory FleetDashboardModel.fromJson(Map<String, dynamic> json) {
    return FleetDashboardModel(
      targetDate: DateTime.parse(json['target_date'] as String),
      totalCapacity: json['total_capacity'] as int? ?? 0,
      totalBooked: json['total_booked'] as int? ?? 0,
      availableCapacity: json['available_capacity'] as int? ?? 0,
      utilizationPercentage: (json['utilization_percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }

  FleetDashboardEntry toEntity() {
    return FleetDashboardEntry(
      targetDate: targetDate,
      totalCapacity: totalCapacity,
      totalBooked: totalBooked,
      availableCapacity: availableCapacity,
      utilizationPercentage: utilizationPercentage,
    );
  }
}
