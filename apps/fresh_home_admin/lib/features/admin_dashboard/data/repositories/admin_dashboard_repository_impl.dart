import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/fleet_dashboard_entry.dart';
import '../../domain/entities/technician_capacity_entry.dart';
import '../../domain/repositories/admin_dashboard_repository.dart';
import '../datasources/admin_dashboard_remote_datasource.dart';

class AdminDashboardRepositoryImpl implements AdminDashboardRepository {
  final AdminDashboardRemoteDataSource remoteDataSource;

  AdminDashboardRepositoryImpl(this.remoteDataSource);

  @override
  Future<Either<Failure, List<FleetDashboardEntry>>> getFleetCapacityDashboard(DateTime startDate, int daysAhead) async {
    try {
      final models = await remoteDataSource.getFleetCapacityDashboard(startDate, daysAhead);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      if (e is PostgrestException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TechnicianCapacityEntry>>> getTechnicianCapacityReport(DateTime targetDate) async {
    try {
      final models = await remoteDataSource.getTechnicianCapacityReport(targetDate);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      if (e is PostgrestException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rescheduleBookingAtomic(String bookingId, DateTime newDate) async {
    try {
      await remoteDataSource.rescheduleBookingAtomic(bookingId, newDate);
      return const Right(null);
    } catch (e) {
      if (e is PostgrestException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reassignBooking(String bookingId, String newTechnicianId) async {
    try {
      await remoteDataSource.reassignBooking(bookingId, newTechnicianId);
      return const Right(null);
    } catch (e) {
      if (e is PostgrestException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forceStatusUpdate(String technicianId, DateTime targetDate, String newStatus) async {
    try {
      await remoteDataSource.forceStatusUpdate(technicianId, targetDate, newStatus);
      return const Right(null);
    } catch (e) {
      if (e is PostgrestException) {
        return Left(ServerFailure(message: e.message));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
