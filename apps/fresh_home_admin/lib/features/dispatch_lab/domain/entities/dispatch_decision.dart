import 'package:equatable/equatable.dart';
import 'virtual_booking.dart';
import 'virtual_technician.dart';

class TechnicianDecisionDetails extends Equatable {
  final String technicianId;
  final String name;
  final double rating;
  final int dailyCapacity;
  final int currentOrders;
  final double utilization;
  final int? lastAssignedOrderIndex;
  final bool isExcluded;
  final String? exclusionReason;
  final Map<String, dynamic> metrics; // e.g. {'rating': 4.5, 'utilization': '0%'}
  final int finalRank; // 1-indexed rank among eligible technicians. 0 if excluded.
  final String rankReason; // Explanation of ranking/position

  const TechnicianDecisionDetails({
    required this.technicianId,
    required this.name,
    required this.rating,
    required this.dailyCapacity,
    required this.currentOrders,
    required this.utilization,
    this.lastAssignedOrderIndex,
    required this.isExcluded,
    this.exclusionReason,
    required this.metrics,
    required this.finalRank,
    required this.rankReason,
  });

  @override
  List<Object?> get props => [
        technicianId,
        name,
        rating,
        dailyCapacity,
        currentOrders,
        utilization,
        lastAssignedOrderIndex,
        isExcluded,
        exclusionReason,
        metrics,
        finalRank,
        rankReason,
      ];
}

class DispatchDecision extends Equatable {
  final VirtualBooking booking;
  final VirtualTechnician? selectedTechnician;
  final String reason;
  final List<TechnicianDecisionDetails> technicianDetails;
  final DateTime timestamp;

  const DispatchDecision({
    required this.booking,
    required this.selectedTechnician,
    required this.reason,
    required this.technicianDetails,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [
        booking,
        selectedTechnician,
        reason,
        technicianDetails,
        timestamp,
      ];
}
