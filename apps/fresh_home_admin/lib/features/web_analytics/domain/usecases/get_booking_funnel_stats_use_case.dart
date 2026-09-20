import 'package:fpdart/fpdart.dart';
import 'package:shared/shared.dart';
import '../entities/booking_funnel_entity.dart';
import '../repositories/web_analytics_repository.dart';

class GetBookingFunnelStatsUseCase {
  final WebAnalyticsRepository repository;

  GetBookingFunnelStatsUseCase({required this.repository});

  Future<Either<Failure, BookingFunnelEntity>> call({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  }) async {
    return await repository.getBookingFunnelStats(
      startDate: startDate,
      endDate: endDate,
      serviceId: serviceId,
    );
  }
}
