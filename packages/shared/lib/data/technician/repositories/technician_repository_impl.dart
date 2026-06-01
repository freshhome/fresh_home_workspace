import 'package:fpdart/fpdart.dart';
import '../../../core/error/failures.dart';
import '../../../core/network/network_info.dart';
import '../../../domain/technician/entities/smart_schedule_entry.dart';
import '../../../domain/technician/entities/technician_pool_status.dart';
import '../../../domain/technician/repositories/technician_repository.dart';
import '../datasources/technician_remote_datasource.dart';

class TechnicianRepositoryImpl implements TechnicianRepository {
  final TechnicianRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  TechnicianRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<TechnicianPoolStatus>>> getDailyPoolBreakdown({
    required String technicianId,
    required DateTime date,
  }) async {
    try {
      final models = await remoteDataSource.getDailyPoolBreakdown(
        technicianId: technicianId,
        date: date,
      );
      return Right(models);
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, WorkloadForecast>> getSmartSchedule(String technicianId, int days) async {
    try {
      final models = await remoteDataSource.getSmartSchedule(technicianId, days);
      
      final avgRisk = models.isEmpty 
          ? 0.0 
          : models.map((e) => e.riskScore).reduce((a, b) => a + b) / models.length;

      return Right(WorkloadForecast(
        schedule: models,
        averageRisk: avgRisk,
        generalRecommendation: _generateGeneralRecommendation(avgRisk),
      ));
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateDailyCapacity({
    required String technicianId,
    required DateTime date,
    required int newCapacity,
    required bool isBlocked,
    String? poolId,
    String? reason,
    String? slotMask,
  }) async {
    try {
      await remoteDataSource.updateDailyCapacity(
        technicianId: technicianId,
        date: date,
        newCapacity: newCapacity,
        isBlocked: isBlocked,
        poolId: poolId,
        reason: reason,
        slotMask: slotMask,
      );
      return const Right(null);
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> resetDailyCapacity({
    required String technicianId,
    required DateTime date,
  }) async {
    try {
      await remoteDataSource.resetDailyCapacity(
        technicianId: technicianId,
        date: date,
      );
      return const Right(null);
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }

  String _generateGeneralRecommendation(double avgRisk) {
    if (avgRisk > 0.8) return 'Critical workload expected. Consider requesting backup.';
    if (avgRisk > 0.5) return 'Moderate pressure. Ensure efficient routing.';
    return 'Optimal capacity. Good for additional bookings.';
  }

  @override
  Future<Either<Failure, bool>> reassignAndBlockCapacity({
    required String technicianId,
    required DateTime date,
    String? poolId,
    int? slotIndex,
  }) async {
    try {
      final success = await remoteDataSource.reassignAndBlockCapacity(
        technicianId: technicianId,
        date: date,
        poolId: poolId,
        slotIndex: slotIndex,
      );
      return Right(success);
    } catch (e) {
      if (e.toString().contains('SocketException') || e.toString().contains('Failed host lookup')) {
        return const Left(NetworkFailure(message: 'No internet connection'));
      }
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

