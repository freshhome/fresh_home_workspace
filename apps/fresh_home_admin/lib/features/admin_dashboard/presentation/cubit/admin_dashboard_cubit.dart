import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import 'admin_dashboard_state.dart';

class AdminDashboardCubit extends Cubit<AdminDashboardState> {
  final AdminDashboardRepository _repository;

  AdminDashboardCubit(this._repository) : super(AdminDashboardInitial());

  Future<void> loadDashboard({DateTime? startDate, int daysAhead = 14}) async {
    emit(AdminDashboardLoading());
    
    final date = startDate ?? DateTime.now();

    final result = await _repository.getFleetCapacityDashboard(date, daysAhead);

    result.fold(
      (failure) {
        debugPrint('\n==================🔴🔴 Dashboard Logic Error 🔴🔴==================');
        debugPrint('Failed to load Fleet Capacity: ${failure.message}');
        debugPrint('===================================================================\n');
        emit(AdminDashboardError(message: failure.message));
      },
      (dashboardData) => emit(AdminDashboardLoaded(
        fleetDashboard: dashboardData,
        selectedDateTechnicians: const [], // Initially empty until a day is picked
        selectedDate: date,
        daysAhead: daysAhead,
      )),
    );
  }

  Future<void>  loadTechnicianDetailsForDate(DateTime date) async {
    if (state is! AdminDashboardLoaded) return;
    
    final currentState = state as AdminDashboardLoaded;
    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.getTechnicianCapacityReport(date);

    result.fold(
      (failure) {
        debugPrint('\n==================🔴🔴 Tech Capacity Error 🔴🔴==================');
        debugPrint('Failed to load Technician Details: ${failure.message}');
        debugPrint('===================================================================\n');
        emit(AdminDashboardError(message: failure.message));
      },
      (techniciansData) => emit(currentState.copyWith(
        selectedDateTechnicians: techniciansData,
        selectedDate: date,
        isActionInProgress: false,
      )),
    );
  }

  Future<void> reassignBooking(String bookingId, String newTechnicianId, DateTime refreshDate) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;
    
    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.reassignBooking(bookingId, newTechnicianId);

    result.fold(
      (failure) {
        emit(AdminDashboardError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminActionSuccess(message: 'tech_action_success_reassigned'));
        await loadTechnicianDetailsForDate(refreshDate); // Refresh grid
      },
    );
  }

  Future<void> rescheduleBooking(String bookingId, DateTime newDate, DateTime refreshDate) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.rescheduleBookingAtomic(bookingId, newDate);

    result.fold(
      (failure) {
        emit(AdminDashboardError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminActionSuccess(message: 'tech_action_success_rescheduled'));
        await loadTechnicianDetailsForDate(refreshDate);
      },
    );
  }

  Future<void> forceStatusUpdate(String technicianId, DateTime targetDate, String newStatus) async {
    if (state is! AdminDashboardLoaded) return;
    final currentState = state as AdminDashboardLoaded;

    emit(currentState.copyWith(isActionInProgress: true));

    final result = await _repository.forceStatusUpdate(technicianId, targetDate, newStatus);

    result.fold(
      (failure) {
        emit(AdminDashboardError(message: failure.message));
        emit(currentState.copyWith(isActionInProgress: false));
      },
      (_) async {
        emit(const AdminActionSuccess(message: 'tech_action_success_status_updated'));
        await loadTechnicianDetailsForDate(targetDate);
      },
    );
  }
}
