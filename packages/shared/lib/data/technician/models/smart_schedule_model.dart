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
    return SmartScheduleModel(
      date: DateTime.parse(json['target_date'] ?? DateTime.now().toIso8601String()),
      status: json['suggested_status'] ?? '',
      utilization: (json['utilization_percentage'] ?? 0.0).toDouble(),
      bookingsCount: (json['current_load'] ?? 0).toInt(),
      capacity: (json['effective_capacity'] ?? 0).toInt(),
      riskScore: (json['risk_score'] ?? 0.0).toDouble(),
      forceMultiplier: (json['force_multiplier'] ?? 1.0).toDouble(),
      suggestion: json['suggestion'] ?? '',
      isOverride: json['is_override'] ?? false,
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
      // Direct mapping if the RPC returns a wrapped object (unlikely for RPC, but checking)
      return WorkloadForecastModel(
        schedule: (json['schedule'] as List)
            .map((e) => SmartScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
        averageRisk: (json['average_risk'] ?? 0.0).toDouble(),
        generalRecommendation: json['general_recommendation'] ?? '',
      );
    } else {
      // If the RPC returns a list directly, we might need a different factory or handle it in datasource
      // But based on existing code, it seems it handles a List<json> and converts to WorkloadForecast
      throw Exception('Unexpected JSON format for WorkloadForecastModel');
    }
  }
}
