import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/availability/day_availability.dart';
import 'package:shared/domain/booking/repositories/availability_repository.dart';

class GetAvailableDaysUseCase {
  final AvailabilityRepository repository;

  GetAvailableDaysUseCase({required this.repository});

  Future<Either<Failure, List<DayAvailability>>> call({
    required String serviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return await repository.getAvailableDays(
      serviceId: serviceId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}
