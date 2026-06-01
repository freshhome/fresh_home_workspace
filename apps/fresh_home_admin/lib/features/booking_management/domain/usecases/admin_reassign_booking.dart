import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/repositories/admin_booking_repository.dart';

class AdminReassignBooking {
  final AdminBookingRepository _repository;

  AdminReassignBooking(this._repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
    required String newTechnicianId,
    required String adminId,
    String? reason,
  }) {
    return _repository.reassignBooking(
      bookingId: bookingId,
      newTechnicianId: newTechnicianId,
      adminId: adminId,
      reason: reason,
    );
  }
}
