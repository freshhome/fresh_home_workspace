import 'package:equatable/equatable.dart';
import 'package:shared/domain/technician/entities/smart_schedule_entry.dart';

import 'package:shared/domain/technician/entities/technician_pool_status.dart';

abstract class SmartScheduleState extends Equatable {
  const SmartScheduleState();

  @override
  List<Object?> get props => [];
}

class SmartScheduleInitial extends SmartScheduleState {}

class SmartScheduleLoading extends SmartScheduleState {}

class SmartScheduleLoaded extends SmartScheduleState {
  final List<SmartScheduleEntry> schedule;
  final String generalRecommendation;
  final List<TechnicianPoolStatus>? poolBreakdown;
  final DateTime selectedDate;
  final DateTime currentMonth;

  const SmartScheduleLoaded({
    required this.schedule,
    required this.generalRecommendation,
    this.poolBreakdown,
    required this.selectedDate,
    required this.currentMonth,
  });

  SmartScheduleLoaded copyWith({
    List<SmartScheduleEntry>? schedule,
    String? generalRecommendation,
    List<TechnicianPoolStatus>? poolBreakdown,
    DateTime? selectedDate,
    DateTime? currentMonth,
  }) {
    return SmartScheduleLoaded(
      schedule: schedule ?? this.schedule,
      generalRecommendation: generalRecommendation ?? this.generalRecommendation,
      poolBreakdown: poolBreakdown ?? this.poolBreakdown,
      selectedDate: selectedDate ?? this.selectedDate,
      currentMonth: currentMonth ?? this.currentMonth,
    );
  }

  @override
  List<Object?> get props => [
        schedule,
        generalRecommendation,
        poolBreakdown,
        selectedDate,
        currentMonth,
      ];
}

class SmartScheduleError extends SmartScheduleState {
  final String message;

  const SmartScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
