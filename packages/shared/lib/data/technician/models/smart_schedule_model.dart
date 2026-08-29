import '../../../domain/technician/entities/smart_schedule_entry.dart';

class SmartScheduleModel extends SmartScheduleEntry {
  const SmartScheduleModel({
    required super.date,
    required super.status,
    required super.utilization,
    required super.bookingsCount,
    required super.capacity,
    required super.riskScore,
    required super.forceMultiplier,
    required super.suggestion,
    required super.isOverride,
  });

  factory SmartScheduleModel.fromJson(Map<String, dynamic> json) {
    // 1. Date: support 'date', 'target_date', 'day'
    final rawDate = json['target_date'] ?? json['date'] ?? json['day'];
    final parsedDate = rawDate != null
        ? DateTime.tryParse(rawDate.toString()) ?? DateTime.now()
        : DateTime.now();

    // 2. Bookings count: support 'bookings_count', 'current_load', 'booked_count', 'total_booked'
    final rawBookings = json['bookings_count'] ??
        json['current_load'] ??
        json['booked_count'] ??
        json['total_booked'] ??
        0;
    final int bookingsCount = (rawBookings is num)
        ? rawBookings.toInt()
        : int.tryParse(rawBookings.toString()) ?? 0;

    // 3. Capacity: support 'capacity', 'effective_capacity', 'total_capacity'
    final rawCapacity = json['capacity'] ??
        json['effective_capacity'] ??
        json['total_capacity'] ??
        0;
    final int capacity = (rawCapacity is num)
        ? rawCapacity.toInt()
        : int.tryParse(rawCapacity.toString()) ?? 0;

    // 4. Status: support 'status', 'suggested_status'
    final String status =
        (json['status'] ?? json['suggested_status'] ?? '').toString();

    // 5. Utilization: support 'utilization', 'utilization_percentage'
    final rawUtil =
        json['utilization'] ?? json['utilization_percentage'] ?? 0.0;
    final double utilization = (rawUtil is num)
        ? rawUtil.toDouble()
        : double.tryParse(rawUtil.toString()) ?? 0.0;

    // 6. Override
    final bool isOverride =
        json['is_override'] == true || json['is_blocked'] == true;

    // 7. Risk score & Force multiplier
    final rawRisk = json['risk_score'] ?? 0.0;
    final double riskScore = (rawRisk is num)
        ? rawRisk.toDouble()
        : double.tryParse(rawRisk.toString()) ?? 0.0;

    final rawForce = json['force_multiplier'] ?? 1.0;
    final double forceMultiplier = (rawForce is num)
        ? rawForce.toDouble()
        : double.tryParse(rawForce.toString()) ?? 1.0;

    final String suggestion = (json['suggestion'] ?? '').toString();

    return SmartScheduleModel(
      date: parsedDate,
      status: status,
      utilization: utilization,
      bookingsCount: bookingsCount,
      capacity: capacity,
      riskScore: riskScore,
      forceMultiplier: forceMultiplier,
      suggestion: suggestion,
      isOverride: isOverride,
    );
  }

  SmartScheduleEntry toEntity() => this;
}

class WorkloadForecastModel extends WorkloadForecast {
  const WorkloadForecastModel({
    required super.schedule,
    required super.averageRisk,
    required super.generalRecommendation,
  });

  factory WorkloadForecastModel.fromJson(Map<String, dynamic> json) {
    if (json['schedule'] != null) {
      return WorkloadForecastModel(
        schedule: (json['schedule'] as List)
            .map((e) => SmartScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        averageRisk: (json['average_risk'] ?? 0.0).toDouble(),
        generalRecommendation: json['general_recommendation'] ?? '',
      );
    } else {
      throw Exception('Unexpected JSON format for WorkloadForecastModel');
    }
  }
}
