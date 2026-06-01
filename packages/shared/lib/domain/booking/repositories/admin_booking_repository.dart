import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

abstract class AdminBookingRepository {
  /// Atomically reassigns a booking to a new technician.
  Future<Either<Failure, void>> reassignBooking({
    required String bookingId,
    required String newTechnicianId,
    required String adminId,
    String? reason,
  });

  /// Cancels a booking with an admin reason.
  Future<Either<Failure, void>> cancelBooking({
    required String bookingId,
    required String adminId,
    required String reason,
  });

  /// Atomically reschedules a booking to a new date.
  Future<Either<Failure, void>> rescheduleBooking({
    required String bookingId,
    required DateTime newDateTime,
    required String adminId,
    String? reason,
  });

  /// Forces a status update (dangerous override).
  Future<Either<Failure, void>> forceStatusUpdate({
    required String bookingId,
    required OrderStatus newStatus,
    required String adminId,
    String? reason,
  });

  // --- Real-time Streams ---
  
  /// Streams all active bookings (assigned, accepted, on_the_way, in_progress).
  Stream<Either<Failure, List<Booking>>> watchActiveBookings();
  
  /// Streams completed bookings.
  Stream<Either<Failure, List<Booking>>> watchCompletedBookings();
  
  /// Streams cancelled bookings.
  Stream<Either<Failure, List<Booking>>> watchCancelledBookings();

  /// Streams ALL bookings regardless of status.
  Stream<Either<Failure, List<Booking>>> watchAllBookings();

  /// Fetches ALL bookings once (non-streamed).
  Future<Either<Failure, List<Booking>>> getAllBookings();
}
