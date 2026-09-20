import 'package:equatable/equatable.dart';

/// Entity representing summary metrics of the booking funnel.
class BookingFunnelSummaryEntity extends Equatable {
  final int totalStarted;
  final int totalCompleted;
  final double overallConversionRate;
  final int? biggestDropOffStep;
  final String? biggestDropOffName;
  final double biggestDropOffRate;
  final int biggestDropOffCount;

  const BookingFunnelSummaryEntity({
    required this.totalStarted,
    required this.totalCompleted,
    required this.overallConversionRate,
    this.biggestDropOffStep,
    this.biggestDropOffName,
    required this.biggestDropOffRate,
    required this.biggestDropOffCount,
  });

  @override
  List<Object?> get props => [
        totalStarted,
        totalCompleted,
        overallConversionRate,
        biggestDropOffStep,
        biggestDropOffName,
        biggestDropOffRate,
        biggestDropOffCount,
      ];
}

/// Entity representing an individual step in the booking funnel.
class BookingFunnelStepEntity extends Equatable {
  final int stepNumber;
  final String eventName;
  final String displayNameAr;
  final int count;
  final double completionRate;
  final int dropOffCount;
  final double dropOffRate;

  const BookingFunnelStepEntity({
    required this.stepNumber,
    required this.eventName,
    required this.displayNameAr,
    required this.count,
    required this.completionRate,
    required this.dropOffCount,
    required this.dropOffRate,
  });

  @override
  List<Object?> get props => [
        stepNumber,
        eventName,
        displayNameAr,
        count,
        completionRate,
        dropOffCount,
        dropOffRate,
      ];
}

/// Entity representing filters applied to the booking funnel query.
class BookingFunnelFiltersEntity extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? serviceId;
  final String trackingVersion;

  const BookingFunnelFiltersEntity({
    this.startDate,
    this.endDate,
    this.serviceId,
    required this.trackingVersion,
  });

  @override
  List<Object?> get props => [startDate, endDate, serviceId, trackingVersion];
}

/// Entity representing the complete booking funnel analytics response.
class BookingFunnelEntity extends Equatable {
  final BookingFunnelSummaryEntity summary;
  final List<BookingFunnelStepEntity> steps;
  final BookingFunnelFiltersEntity filters;

  const BookingFunnelEntity({
    required this.summary,
    required this.steps,
    required this.filters,
  });

  @override
  List<Object?> get props => [summary, steps, filters];
}
