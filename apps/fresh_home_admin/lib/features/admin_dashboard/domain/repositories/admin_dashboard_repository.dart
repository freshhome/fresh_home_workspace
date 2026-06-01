import 'package:fpdart/fpdart.dart';
import 'package:fresh_home_admin/features/admin_dashboard/domain/entities/fleet_dashboard_entry.dart';
import 'package:fresh_home_admin/features/admin_dashboard/domain/entities/technician_capacity_entry.dart';
import 'package:shared/core/error/failures.dart';

abstract class AdminDashboardRepository {
  Future<Either<Failure, List<FleetDashboardEntry>>> getFleetCapacityDashboard(DateTime startDate, int daysAhead);
  Future<Either<Failure, List<TechnicianCapacityEntry>>> getTechnicianCapacityReport(DateTime targetDate);
  Future<Either<Failure, void>> rescheduleBookingAtomic(String bookingId, DateTime newDate);
  Future<Either<Failure, void>> reassignBooking(String bookingId, String newTechnicianId);
  Future<Either<Failure, void>> forceStatusUpdate(String technicianId, DateTime targetDate, String newStatus);
}
