import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/usecase/usecase.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/repositories/booking_repository.dart';
import 'package:shared/domain/user/entities/user/address.dart';

class UpdateBookingAddressUseCase implements UseCase<void, UpdateBookingAddressParams> {
  final BookingRepository repository;

  UpdateBookingAddressUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateBookingAddressParams params) {
    return repository.updateBookingAddress(
      bookingId: params.bookingId,
      address: params.address,
      contact: params.contact,
      actorId: params.actorId,
    );
  }
}

class UpdateBookingAddressParams extends Equatable {
  final String bookingId;
  final Address address;
  final Contact contact;
  final String actorId;

  const UpdateBookingAddressParams({
    required this.bookingId,
    required this.address,
    required this.contact,
    required this.actorId,
  });

  @override
  List<Object?> get props => [bookingId, address, contact, actorId];
}
