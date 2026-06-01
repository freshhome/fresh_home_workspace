import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetUserBookingsUseCase {
  final BookingRepository repository;

  GetUserBookingsUseCase({required this.repository});

  Future<Either<Failure, List<Booking>>> call({required String userId}) async {
    return await repository.getUserBookings(userId: userId);
  }
}
