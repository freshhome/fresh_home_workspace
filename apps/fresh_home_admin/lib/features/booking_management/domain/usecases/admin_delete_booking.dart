import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/repositories/admin_booking_repository.dart';

class AdminDeleteBooking {
  final AdminBookingRepository _repository;

  AdminDeleteBooking(this._repository);

  Future<Either<Failure, void>> call({
    required String bookingId,
  }) {
    return _repository.deleteBooking(
      bookingId: bookingId,
    );
  }
}
