import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../entities/web_analytics_entity.dart';
import '../repositories/web_analytics_repository.dart';

class GetTodayAnalyticsUseCase {
  final WebAnalyticsRepository repository;

  GetTodayAnalyticsUseCase({required this.repository});

  Future<Either<Failure, WebAnalyticsEntity>> call() async {
    return await repository.getTodayAnalytics();
  }
}
