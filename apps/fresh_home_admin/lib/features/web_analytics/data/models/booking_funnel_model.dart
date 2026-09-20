import '../../domain/entities/booking_funnel_entity.dart';

class BookingFunnelSummaryModel extends BookingFunnelSummaryEntity {
  const BookingFunnelSummaryModel({
    required super.totalStarted,
    required super.totalCompleted,
    required super.overallConversionRate,
    super.biggestDropOffStep,
    super.biggestDropOffName,
    required super.biggestDropOffRate,
    required super.biggestDropOffCount,
  });

  factory BookingFunnelSummaryModel.fromJson(Map<String, dynamic> json) {
    return BookingFunnelSummaryModel(
      totalStarted: (json['total_started'] as num?)?.toInt() ?? 0,
      totalCompleted: (json['total_completed'] as num?)?.toInt() ?? 0,
      overallConversionRate:
          (json['overall_conversion_rate'] as num?)?.toDouble() ?? 0.0,
      biggestDropOffStep: (json['biggest_drop_off_step'] as num?)?.toInt(),
      biggestDropOffName: json['biggest_drop_off_name'] as String?,
      biggestDropOffRate:
          (json['biggest_drop_off_rate'] as num?)?.toDouble() ?? 0.0,
      biggestDropOffCount:
          (json['biggest_drop_off_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class BookingFunnelStepModel extends BookingFunnelStepEntity {
  const BookingFunnelStepModel({
    required super.stepNumber,
    required super.eventName,
    required super.displayNameAr,
    required super.count,
    required super.completionRate,
    required super.dropOffCount,
    required super.dropOffRate,
  });

  factory BookingFunnelStepModel.fromJson(Map<String, dynamic> json) {
    return BookingFunnelStepModel(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 0,
      eventName: json['event_name'] as String? ?? '',
      displayNameAr: json['display_name_ar'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
      completionRate: (json['completion_rate'] as num?)?.toDouble() ?? 0.0,
      dropOffCount: (json['drop_off_count'] as num?)?.toInt() ?? 0,
      dropOffRate: (json['drop_off_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class BookingFunnelFiltersModel extends BookingFunnelFiltersEntity {
  const BookingFunnelFiltersModel({
    super.startDate,
    super.endDate,
    super.serviceId,
    required super.trackingVersion,
  });

  factory BookingFunnelFiltersModel.fromJson(Map<String, dynamic> json) {
    return BookingFunnelFiltersModel(
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      serviceId: json['service_id'] as String?,
      trackingVersion: json['tracking_version'] as String? ?? 'v1',
    );
  }
}

class BookingFunnelModel extends BookingFunnelEntity {
  const BookingFunnelModel({
    required super.summary,
    required super.steps,
    required super.filters,
  });

  factory BookingFunnelModel.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] as Map<String, dynamic>? ?? {};
    final stepsJson = json['steps'] as List<dynamic>? ?? [];
    final filtersJson = json['filters_applied'] as Map<String, dynamic>? ?? {};

    return BookingFunnelModel(
      summary: BookingFunnelSummaryModel.fromJson(summaryJson),
      steps: stepsJson
          .map((s) => BookingFunnelStepModel.fromJson(s as Map<String, dynamic>))
          .toList(),
      filters: BookingFunnelFiltersModel.fromJson(filtersJson),
    );
  }
}
