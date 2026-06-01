import 'package:equatable/equatable.dart';

class SmartScheduleEntry extends Equatable {
  final DateTime date;
  final String status;
  final double utilization;
  final int bookingsCount;
  final int capacity;
  final double riskScore;
  final double forceMultiplier;
  final String suggestion;
  final bool isOverride;

  const SmartScheduleEntry({
    required this.date,
    required this.status,
    required this.utilization,
    required this.bookingsCount,
    required this.capacity,
    required this.riskScore,
    required this.forceMultiplier,
    required this.suggestion,
    required this.isOverride,
  });

  @override
  List<Object?> get props => [
        date,
        status,
        utilization,
        bookingsCount,
        capacity,
        riskScore,
        forceMultiplier,
        suggestion,
        isOverride,
      ];
}

class WorkloadForecast extends Equatable {
  final List<SmartScheduleEntry> schedule;
  final double averageRisk;
  final String generalRecommendation;

  const WorkloadForecast({
    required this.schedule,
    required this.averageRisk,
    required this.generalRecommendation,
  });

  @override
  List<Object?> get props => [schedule, averageRisk, generalRecommendation];
}
