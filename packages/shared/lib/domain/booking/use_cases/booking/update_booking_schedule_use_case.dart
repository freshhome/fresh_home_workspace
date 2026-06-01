import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/usecase/usecase.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';

class UpdateBookingScheduleUseCase implements UseCase<void, UpdateBookingScheduleParams> {
  final BookingRepository repository;

  UpdateBookingScheduleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBookingScheduleParams params) {
    return repository.updateBookingSchedule(
      bookingId: params.bookingId,
      newDay: params.newDay,
      newTimeSlot: params.newTimeSlot,
      actorId: params.actorId,
    );
  }
}

class UpdateBookingScheduleParams extends Equatable {
  final String bookingId;
  final DateTime newDay;
  final String newTimeSlot;
  final String actorId;

  const UpdateBookingScheduleParams({
    required this.bookingId,
    required this.newDay,
    required this.newTimeSlot,
    required this.actorId,
  });

  @override
  List<Object?> get props => [bookingId, newDay, newTimeSlot, actorId];
}
