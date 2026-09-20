import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../../domain/entities/booking_funnel_entity.dart';
import '../../domain/entities/web_analytics_entity.dart';
import '../../domain/repositories/web_analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';
import '../datasources/booking_funnel_remote_data_source.dart';

class WebAnalyticsRepositoryImpl implements WebAnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;
  final BookingFunnelRemoteDataSource? funnelRemoteDataSource;

  WebAnalyticsRepositoryImpl({
    required this.remoteDataSource,
    this.funnelRemoteDataSource,
  });

  @override
  Future<Either<Failure, WebAnalyticsEntity>> getTodayAnalytics() async {
    try {
      final model = await remoteDataSource.getTodayAnalytics();
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, BookingFunnelEntity>> getBookingFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  }) async {
    if (funnelRemoteDataSource == null) {
      return Left(ServerFailure(message: 'Funnel remote data source is not configured'));
    }
    try {
      final model = await funnelRemoteDataSource!.getBookingFunnelStats(
        startDate: startDate,
        endDate: endDate,
        serviceId: serviceId,
      );
      return Right(model);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
