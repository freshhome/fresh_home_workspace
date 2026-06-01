import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../repositories/admin_booking_repository.dart';

class AdminRescheduleBookingUseCase {
  final AdminBookingRepository _repository;

  AdminRescheduleBookingUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
    required DateTime newDateTime,
    required String adminId,
    String? reason,
  }) {
    return _repository.rescheduleBooking(
      bookingId: bookingId,
      newDateTime: newDateTime,
      adminId: adminId,
      reason: reason,
    );
  }
}
