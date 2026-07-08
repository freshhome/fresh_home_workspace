import 'package:equatable/equatable.dart';

/// Represents a named capacity resource bucket owned by a technician.
/// Multiple [TechnicianSkill]s can point to the same pool to share daily capacity.
class CapacityPool extends Equatable {
  final String id;
  final String technicianId;
  final String title;
  final String mainServiceId;
  final int maxDailyCapacity;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CapacityPool({
    required this.id,
    required this.technicianId,
    required this.title,
    required this.mainServiceId,
    required this.maxDailyCapacity,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        technicianId,
        title,
        mainServiceId,
        maxDailyCapacity,
        createdAt,
        updatedAt,
      ];
}
