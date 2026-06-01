import 'package:equatable/equatable.dart';
import '../../domain/entities/fleet_dashboard_entry.dart';
import '../../domain/entities/technician_capacity_entry.dart';

abstract class AdminDashboardState extends Equatable {
  const AdminDashboardState();

  @override
  List<Object?> get props => [];
}

class AdminDashboardInitial extends AdminDashboardState {}

class AdminDashboardLoading extends AdminDashboardState {}

class AdminDashboardLoaded extends AdminDashboardState {
  final List<FleetDashboardEntry> fleetDashboard;
  final List<TechnicianCapacityEntry> selectedDateTechnicians;
  final DateTime selectedDate;
  final int daysAhead;
  final bool isActionInProgress;

  const AdminDashboardLoaded({
    required this.fleetDashboard,
    required this.selectedDateTechnicians,
    required this.selectedDate,
    required this.daysAhead,
    this.isActionInProgress = false,
  });

  AdminDashboardLoaded copyWith({
    List<FleetDashboardEntry>? fleetDashboard,
    List<TechnicianCapacityEntry>? selectedDateTechnicians,
    DateTime? selectedDate,
    int? daysAhead,
    bool? isActionInProgress,
  }) {
    return AdminDashboardLoaded(
      fleetDashboard: fleetDashboard ?? this.fleetDashboard,
      selectedDateTechnicians: selectedDateTechnicians ?? this.selectedDateTechnicians,
      selectedDate: selectedDate ?? this.selectedDate,
      daysAhead: daysAhead ?? this.daysAhead,
      isActionInProgress: isActionInProgress ?? this.isActionInProgress,
    );
  }

  @override
  List<Object?> get props => [
        fleetDashboard,
        selectedDateTechnicians,
        selectedDate,
        daysAhead,
        isActionInProgress,
      ];
}

class AdminDashboardError extends AdminDashboardState {
  final String message;

  const AdminDashboardError({required this.message});

  @override
  List<Object?> get props => [message];
}

class AdminActionSuccess extends AdminDashboardState {
  final String message;

  const AdminActionSuccess({required this.message});

  @override
  List<Object?> get props => [message];
}
