import 'package:equatable/equatable.dart';

/// Represents a technician's skill: the ability to perform a specific
/// sub-service, drawing from a specific [CapacityPool].
class TechnicianSkill extends Equatable {
  final String id;
  final String technicianId;
  final String subServiceId;
  final String capacityPoolId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TechnicianSkill({
    required this.id,
    required this.technicianId,
    required this.subServiceId,
    required this.capacityPoolId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [
        id,
        technicianId,
        subServiceId,
        capacityPoolId,
        isActive,
        createdAt,
        updatedAt,
      ];
}
