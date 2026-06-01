import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../entities/smart_schedule_entry.dart';
import '../entities/technician_pool_status.dart';

abstract class TechnicianRepository {
  Future<Either<Failure, WorkloadForecast>> getSmartSchedule(String technicianId, int days);
  Future<Either<Failure, void>> updateDailyCapacity({
    required String technicianId,
    required DateTime date,
    required int newCapacity,
    required bool isBlocked,
    String? poolId,
    String? reason,
    String? slotMask,
  });
  Future<Either<Failure, void>> resetDailyCapacity({
    required String technicianId,
    required DateTime date,
  });
  Future<Either<Failure, List<TechnicianPoolStatus>>> getDailyPoolBreakdown({
    required String technicianId,
    required DateTime date,
  });
  Future<Either<Failure, bool>> reassignAndBlockCapacity({
    required String technicianId,
    required DateTime date,
    String? poolId,
    int? slotIndex,
  });
}
