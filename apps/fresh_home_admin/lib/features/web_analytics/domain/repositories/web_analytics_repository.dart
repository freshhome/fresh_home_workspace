import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../entities/booking_funnel_entity.dart';
import '../entities/web_analytics_entity.dart';

abstract class WebAnalyticsRepository {
  Future<Either<Failure, WebAnalyticsEntity>> getTodayAnalytics();
  Future<Either<Failure, BookingFunnelEntity>> getBookingFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  });
}
