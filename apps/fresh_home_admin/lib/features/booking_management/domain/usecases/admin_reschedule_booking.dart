import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/repositories/admin_booking_repository.dart';

class AdminRescheduleBooking {
  final AdminBookingRepository _repository;

  AdminRescheduleBooking(this._repository);

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
