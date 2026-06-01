import 'package:fpdart/fpdart.dart';
import 'package:shared/core/error/failures.dart';
import 'package:shared/core/error/exceptions.dart';
import 'package:shared/data/booking/datasources/availability_remote_datasource.dart';
import 'package:shared/domain/booking/entities/availability/day_availability.dart';
import 'package:shared/domain/booking/repositories/availability_repository.dart';

class AvailabilityRepositoryImpl implements AvailabilityRepository {
  final AvailabilityRemoteDataSource remoteDataSource;

  AvailabilityRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<DayAvailability>>> getAvailableDays({
    required String serviceId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final results = await remoteDataSource.getAvailableDays(
        serviceId: serviceId,
        startDate: startDate.toIso8601String().split('T')[0],
        endDate: endDate.toIso8601String().split('T')[0],
      );

      final availabilities = results.map((json) {
        return DayAvailability(
          date: DateTime.parse(json['available_date'] as String),
          isAvailable: json['is_available'] as bool,
        );
      }).toList();

      return Right(availabilities);
    } on SupabaseExceptionApp catch (e) {
      return Left(ServerFailure(message: e.message, code: e.code));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
