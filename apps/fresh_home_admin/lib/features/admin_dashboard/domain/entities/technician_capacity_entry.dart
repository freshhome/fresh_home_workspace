import 'package:equatable/equatable.dart';

class TechnicianCapacityEntry extends Equatable {
  final String technicianId;
  final String technicianName;
  final String? mainServiceId;
  final int workload;
  final int capacity;
  final String status;
  final double utilizationPercentage;

  const TechnicianCapacityEntry({
    required this.technicianId,
    required this.technicianName,
    this.mainServiceId,
    required this.workload,
    required this.capacity,
    required this.status,
    required this.utilizationPercentage,
  });

  @override
  List<Object?> get props => [
        technicianId,
        technicianName,
        mainServiceId,
        workload,
        capacity,
        status,
        utilizationPercentage,
      ];
}
