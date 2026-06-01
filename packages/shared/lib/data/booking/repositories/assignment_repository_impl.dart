import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/data/booking/datasources/assignment_remote_data_source.dart';
import 'package:shared/domain/booking/entities/availability/day_availability.dart';
import 'package:shared/domain/booking/repositories/assignment_repository.dart';
import 'package:shared/domain/user/entities/user/technician_profile.dart';

class AssignmentRepositoryImpl implements AssignmentRepository {
  final AssignmentRemoteDataSource _remoteDataSource;

  const AssignmentRepositoryImpl({
    required AssignmentRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<TechnicianProfile>>> getAvailableTechnicians({
    required String subServiceId,
    required DateTime date,
  }) async {
    try {
      final result = await _remoteDataSource.getAvailableTechnicians(
        subServiceId: subServiceId,
        date: date,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DayAvailability>>> getAvailableDays({
    required String subServiceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final result = await _remoteDataSource.getAvailableDays(
        subServiceId: subServiceId,
        startDate: startDate,
        endDate: endDate,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createAtomicBooking({
    required String userId,
    required String subServiceId,
    required String technicianId,
    required DateTime scheduledDay,
    required Map<String, dynamic> addressSnapshot,
    required Map<String, dynamic> serviceSnapshot,
    required Map<String, dynamic> priceSnapshot,
  }) async {
    try {
      final bookingId = await _remoteDataSource.createAtomicBooking(
        userId: userId,
        subServiceId: subServiceId,
        technicianId: technicianId,
        scheduledDay: scheduledDay,
        addressSnapshot: addressSnapshot,
        serviceSnapshot: serviceSnapshot,
        priceSnapshot: priceSnapshot,
      );
      return Right(bookingId);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
