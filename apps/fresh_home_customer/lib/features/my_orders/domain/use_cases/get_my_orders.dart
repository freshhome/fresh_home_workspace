import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';

class GetMyOrders {
  final BookingRepository repository;

  GetMyOrders(this.repository);

  Stream<Either<Failure, List<Booking>>> call(String userId) {
    return repository.watchUserBookings(userId: userId);
  }
}
