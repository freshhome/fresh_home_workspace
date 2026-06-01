import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';

class TransitionBookingParams {
  final String bookingId;
  final OrderStatus newStatus;
  final String actorId;
  final String actorRole;
  final String? reason;
  final String? notes;
  final Map<String, dynamic>? metadata;

  const TransitionBookingParams({
    required this.bookingId,
    required this.newStatus,
    required this.actorId,
    required this.actorRole,
    this.reason,
    this.notes,
    this.metadata,
  });
}

class TransitionBookingUseCase {
  final BookingRepository repository;

  TransitionBookingUseCase({required this.repository});

  Future<Either<Failure, void>> call(TransitionBookingParams params) async {
    return await repository.transitionBooking(
      bookingId: params.bookingId,
      newStatus: params.newStatus,
      actorId: params.actorId,
      actorRole: params.actorRole,
      reason: params.reason,
      notes: params.notes,
      metadata: params.metadata,
    );
  }
}
