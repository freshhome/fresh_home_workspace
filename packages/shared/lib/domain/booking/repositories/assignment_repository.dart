import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/availability/day_availability.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';

/// Contract for the assignment engine — all technician availability
/// and atomic booking operations go through this repository.
abstract class AssignmentRepository {
  /// Returns technicians who can perform [subServiceId] on [date]
  /// and have remaining capacity in their linked pool.
  Future<Either<Failure, List<TechnicianProfile>>> getAvailableTechnicians({
    required String subServiceId,
    required DateTime date,
  });

  /// Returns a per-day availability map between [startDate] and [endDate].
  Future<Either<Failure, List<DayAvailability>>> getAvailableDays({
    required String subServiceId,
    required DateTime startDate,
    required DateTime endDate,
  });

  /// Atomically creates a booking after verifying pool capacity.
  /// Returns the new booking ID on success or a [Failure] if capacity is full.
  Future<Either<Failure, String>> createAtomicBooking({
    required String userId,
    required String subServiceId,
    required String technicianId,
    required DateTime scheduledDay,
    required Map<String, dynamic> addressSnapshot,
    required Map<String, dynamic> serviceSnapshot,
    required Map<String, dynamic> priceSnapshot,
  });
}
