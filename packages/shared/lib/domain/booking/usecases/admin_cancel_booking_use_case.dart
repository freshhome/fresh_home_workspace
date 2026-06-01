import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import '../repositories/admin_booking_repository.dart';

class AdminCancelBookingUseCase {
  final AdminBookingRepository _repository;

  AdminCancelBookingUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
    required String adminId,
    required String reason,
  }) {
    return _repository.cancelBooking(
      bookingId: bookingId,
      adminId: adminId,
      reason: reason,
    );
  }
}
