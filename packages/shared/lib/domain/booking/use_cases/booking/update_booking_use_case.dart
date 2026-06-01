import 'package:fpdart/fpdart.dart';

import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/core/error/failures.dart';

class UpdateBookingUseCase {
  final BookingRepository repository;

  UpdateBookingUseCase({required this.repository});

  Future<Either<Failure, void>> call({required Booking booking}) async {
    return await repository.updateBooking(booking: booking);
  }
}
