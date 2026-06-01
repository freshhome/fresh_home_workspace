import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';

class GetAllOrders {
  final BookingRepository repository;

  GetAllOrders(this.repository);

  Stream<Either<Failure, List<Booking>>> call({List<String>? serviceNames}) {
    return repository.watchAllBookings(serviceNames: serviceNames);
  }
}
