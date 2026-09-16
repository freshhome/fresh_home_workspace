import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../../domain/entities/web_analytics_entity.dart';
import '../../domain/repositories/web_analytics_repository.dart';
import '../datasources/analytics_remote_data_source.dart';

class WebAnalyticsRepositoryImpl implements WebAnalyticsRepository {
  final AnalyticsRemoteDataSource remoteDataSource;

  WebAnalyticsRepositoryImpl({required this.remoteDataSource});

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
}
