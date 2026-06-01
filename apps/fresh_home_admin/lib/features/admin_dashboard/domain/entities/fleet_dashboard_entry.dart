import 'package:equatable/equatable.dart';

class FleetDashboardEntry extends Equatable {
  final DateTime targetDate;
  final int totalCapacity;
  final int totalBooked;
  final int availableCapacity;
  final double utilizationPercentage;

  const FleetDashboardEntry({
    required this.targetDate,
    required this.totalCapacity,
    required this.totalBooked,
    required this.availableCapacity,
    required this.utilizationPercentage,
  });

  @override
  List<Object?> get props => [
        targetDate,
        totalCapacity,
        totalBooked,
        availableCapacity,
        utilizationPercentage,
      ];
}
