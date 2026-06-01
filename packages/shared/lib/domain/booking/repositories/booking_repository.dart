import 'package:fpdart/fpdart.dart';

import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/user/entities/user/address.dart';

abstract class BookingRepository {
  Future<Either<Failure, String>> createBooking({required Booking booking});
  Future<Either<Failure, Booking>> getBookingById({required String id});
  Future<Either<Failure, List<Booking>>> getUserBookings({required String userId});
  Stream<Either<Failure, List<Booking>>> watchUserBookings({required String userId});
  Stream<Either<Failure, List<Booking>>> watchAllBookings({List<String>? serviceNames});
  Stream<Either<Failure, Booking>> watchBooking({required String bookingId});
  Future<Either<Failure, void>> updateBooking({required Booking booking});
  Future<Either<Failure, void>> transitionBooking({
    required String bookingId,
    required OrderStatus newStatus,
    required String actorId,
    required String actorRole,
    String? reason,
    String? notes,
    Map<String, dynamic>? metadata,
  });
  Future<Either<Failure, void>> cancelBooking({required String bookingId});
  Future<Either<Failure, void>> updateBookingSchedule({
    required String bookingId,
    required DateTime newDay,
    required String newTimeSlot,
    required String actorId,
  });
  Future<Either<Failure, void>> updateBookingAddress({
    required String bookingId,
    required Address address,
    required Contact contact,
    required String actorId,
  });
  Future<Either<Failure, BookingPricing>> calculateBookingPrice({
    required String subServiceId,
    required Map<String, dynamic> pricingInputs,
  });
}
