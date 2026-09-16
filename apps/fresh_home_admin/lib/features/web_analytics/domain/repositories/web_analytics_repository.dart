import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../entities/web_analytics_entity.dart';

abstract class WebAnalyticsRepository {
  Future<Either<Failure, WebAnalyticsEntity>> getTodayAnalytics();
}
