import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/admin_booking_repository.dart';

class AdminWatchBookings {
  final AdminBookingRepository _repository;

  AdminWatchBookings(this._repository);

  Stream<Either<Failure, List<Booking>>> watchActive() => _repository.watchActiveBookings();
  Stream<Either<Failure, List<Booking>>> watchCompleted() => _repository.watchCompletedBookings();
  Stream<Either<Failure, List<Booking>>> watchCancelled() => _repository.watchCancelledBookings();
  Stream<Either<Failure, List<Booking>>> watchAll() => _repository.watchAllBookings();
  Future<Either<Failure, List<Booking>>> getAll() => _repository.getAllBookings();
}
