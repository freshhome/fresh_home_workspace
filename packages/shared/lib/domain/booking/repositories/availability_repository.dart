import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/availability/day_availability.dart';

abstract class AvailabilityRepository {
  Future<Either<Failure, List<DayAvailability>>> getAvailableDays({
    required String serviceId,
    required DateTime startDate,
    required DateTime endDate,
  });
}
