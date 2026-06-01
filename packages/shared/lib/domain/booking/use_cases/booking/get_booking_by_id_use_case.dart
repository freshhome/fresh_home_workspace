import 'package:fpdart/fpdart.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/core/error/failures.dart';

class GetBookingByIdUseCase {
  final BookingRepository repository;

  GetBookingByIdUseCase({required this.repository});

  Future<Either<Failure, Booking>> call({required String id}) async {
    return await repository.getBookingById(id: id);
  }
}
