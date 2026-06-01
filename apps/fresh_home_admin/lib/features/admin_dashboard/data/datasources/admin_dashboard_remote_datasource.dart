import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/fleet_dashboard_model.dart';
import '../models/technician_capacity_model.dart';

abstract class AdminDashboardRemoteDataSource {
  Future<List<FleetDashboardModel>> getFleetCapacityDashboard(DateTime startDate, int daysAhead);
  Future<List<TechnicianCapacityModel>> getTechnicianCapacityReport(DateTime targetDate);
  Future<void> rescheduleBookingAtomic(String bookingId, DateTime newDate);
  Future<void> reassignBooking(String bookingId, String newTechnicianId);
  Future<void> forceStatusUpdate(String technicianId, DateTime targetDate, String newStatus);
}

class AdminDashboardRemoteDataSourceImpl implements AdminDashboardRemoteDataSource {
  final SupabaseClient _supabase;

  AdminDashboardRemoteDataSourceImpl(this._supabase);

  @override
  Future<List<FleetDashboardModel>> getFleetCapacityDashboard(DateTime startDate, int daysAhead) async {
    final response = await _supabase.rpc(
      'get_fleet_capacity_dashboard',
      params: {
        'p_start_date': startDate.toIso8601String().split('T')[0],
        'p_days_ahead': daysAhead,
      },
    );

    if (response is List) {
      return response.map((json) => FleetDashboardModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load fleet dashboard');
  }

  @override
  Future<List<TechnicianCapacityModel>> getTechnicianCapacityReport(DateTime targetDate) async {
    final response = await _supabase.rpc(
      'get_technician_capacity_report',
      params: {
        'p_target_date': targetDate.toIso8601String().split('T')[0],
      },
    );

    if (response is List) {
      return response.map((json) => TechnicianCapacityModel.fromJson(json as Map<String, dynamic>)).toList();
    }
    throw Exception('Failed to load technician capacity report');
  }

  @override
  Future<void> rescheduleBookingAtomic(String bookingId, DateTime newDate) async {
    await _supabase.rpc(
      'admin_reschedule_booking_atomic',
      params: {
        'p_booking_id': bookingId,
        'p_new_date': newDate.toIso8601String(),
      },
    );
  }

  @override
  Future<void> reassignBooking(String bookingId, String newTechnicianId) async {
    await _supabase.rpc(
      'admin_reassign_booking',
      params: {
        'p_booking_id': bookingId,
        'p_new_technician_id': newTechnicianId,
      },
    );
  }

  @override
  Future<void> forceStatusUpdate(String technicianId, DateTime targetDate, String newStatus) async {
    await _supabase.rpc(
      'admin_force_status_update',
      params: {
        'p_technician_id': technicianId,
        'p_target_date': targetDate.toIso8601String().split('T')[0],
        'p_new_status': newStatus,
      },
    );
  }
}
