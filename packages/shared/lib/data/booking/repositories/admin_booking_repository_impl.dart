import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';
import 'package:shared/domain/booking/repositories/admin_booking_repository.dart';
import '../datasources/admin_booking_remote_data_source.dart';
import '../mappers/booking_mapper.dart';

class AdminBookingRepositoryImpl implements AdminBookingRepository {
  final AdminBookingRemoteDataSource _remoteDataSource;

  AdminBookingRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> reassignBooking({
    required String bookingId,
    required String newTechnicianId,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _remoteDataSource.reassignBooking(
        bookingId: bookingId,
        newTechnicianId: newTechnicianId,
        adminId: adminId,
        reason: reason,
      );
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> cancelBooking({
    required String bookingId,
    required String adminId,
    required String reason,
  }) async {
    try {
      await _remoteDataSource.cancelBooking(
        bookingId: bookingId,
        adminId: adminId,
        reason: reason,
      );
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> rescheduleBooking({
    required String bookingId,
    required DateTime newDateTime,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _remoteDataSource.rescheduleBooking(
        bookingId: bookingId,
        adminId: adminId,
        newDateTime: newDateTime,
        reason: reason,
      );
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forceStatusUpdate({
    required String bookingId,
    required OrderStatus newStatus,
    required String adminId,
    String? reason,
  }) async {
    try {
      await _remoteDataSource.forceStatusUpdate(
        bookingId: bookingId,
        newStatus: newStatus,
        adminId: adminId,
        reason: reason,
      );
      return const Right(null);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Booking>>> watchActiveBookings() {
    return _remoteDataSource.watchActiveBookings().map(
      (models) => Right<Failure, List<Booking>>(
        models.map((m) => BookingMapper.remoteToEntity(m)).toList(),
      ),
    ).handleError((e) => Left<Failure, List<Booking>>(ServerFailure(message: e.toString())));
  }

  @override
  Stream<Either<Failure, List<Booking>>> watchCompletedBookings() {
    return _remoteDataSource.watchCompletedBookings().map(
      (models) => Right<Failure, List<Booking>>(
        models.map((m) => BookingMapper.remoteToEntity(m)).toList(),
      ),
    ).handleError((e) => Left<Failure, List<Booking>>(ServerFailure(message: e.toString())));
  }

  @override
  Stream<Either<Failure, List<Booking>>> watchCancelledBookings() {
    return _remoteDataSource.watchCancelledBookings().map(
      (models) => Right<Failure, List<Booking>>(
        models.map((m) => BookingMapper.remoteToEntity(m)).toList(),
      ),
    ).handleError((e) => Left<Failure, List<Booking>>(ServerFailure(message: e.toString())));
  }

  @override
  Stream<Either<Failure, List<Booking>>> watchAllBookings() {
    return _remoteDataSource.watchAllBookings().map(
      (models) => Right<Failure, List<Booking>>(
        models.map((m) => BookingMapper.remoteToEntity(m)).toList(),
      ),
    ).handleError((e) => Left<Failure, List<Booking>>(ServerFailure(message: e.toString())));
  }

  @override
  Future<Either<Failure, List<Booking>>> getAllBookings() async {
    try {
      final models = await _remoteDataSource.getAllBookings();
      return Right(models.map((m) => BookingMapper.remoteToEntity(m)).toList());
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
