import 'package:fpdart/fpdart.dart';

import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/core/error/failures.dart';

class CreateBookingUseCase {
  final BookingRepository repository;

  CreateBookingUseCase({required this.repository});

  Future<Either<Failure, String>> call({required Booking booking}) async {
    return await repository.createBooking(booking: booking);
  }
}
