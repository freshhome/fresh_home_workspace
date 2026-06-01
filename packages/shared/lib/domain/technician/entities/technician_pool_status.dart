import 'package:equatable/equatable.dart';

class TechnicianPoolStatus extends Equatable {
  final String poolId;
  final String title;
  final int maxCapacity;
  final int currentLoad;
  final bool isBlocked;
  final int? overrideCapacity;
  final bool isOverride;
  final String? slotMask;
  final List<String>? services;

  const TechnicianPoolStatus({
    required this.poolId,
    required this.title,
    required this.maxCapacity,
    required this.currentLoad,
    required this.isBlocked,
    this.overrideCapacity,
    required this.isOverride,
    this.slotMask,
    this.services,
  });

  int get effectiveCapacity {
    if (isBlocked) return 0;
    return overrideCapacity ?? maxCapacity;
  }

  @override
  List<Object?> get props => [
        poolId,
        title,
        maxCapacity,
        currentLoad,
        isBlocked,
        overrideCapacity,
        isOverride,
        slotMask,
        services,
      ];
}
