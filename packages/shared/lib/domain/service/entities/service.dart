import 'package:equatable/equatable.dart';

class MainService extends Equatable {
  final String id;
  final String name;
  final String description;
  final String iconUrl;
  final List<SubService> subServices;

  const MainService({
    required this.id,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.subServices,
  });

  factory MainService.fromJson(Map<String, dynamic> json) {
    return MainService(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconUrl: json['iconUrl'] ?? '',
      subServices: (json['sub_services'] as List? ?? [])
          .map((e) => SubService.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, name, description, iconUrl, subServices];
}

class SubService extends Equatable {
  final String id;
  final String mainServiceId;
  final String name;
  final String description;
  final double basePrice;
  final int estimatedDurationMinutes;

  const SubService({
    required this.id,
    required this.mainServiceId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.estimatedDurationMinutes,
  });

  factory SubService.fromJson(Map<String, dynamic> json) {
    return SubService(
      id: json['id'] ?? '',
      mainServiceId: json['mainServiceId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      basePrice: (json['basePrice'] ?? 0.0).toDouble(),
      estimatedDurationMinutes: (json['estimatedDurationMinutes'] ?? 0).toInt(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        mainServiceId,
        name,
        description,
        basePrice,
        estimatedDurationMinutes,
      ];
}

class ServiceAvailability extends Equatable {
  final DateTime date;
  final List<TimeSlot> availableSlots;

  const ServiceAvailability({
    required this.date,
    required this.availableSlots,
  });

  factory ServiceAvailability.fromJson(Map<String, dynamic> json) {
    return ServiceAvailability(
      date: DateTime.parse(json['date'] ?? DateTime.now().toIso8601String()),
      availableSlots: (json['availableSlots'] as List? ?? [])
          .map((e) => TimeSlot.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [date, availableSlots];
}

class TimeSlot extends Equatable {
  final String startTime;
  final String endTime;
  final bool isAvailable;
  final String? technicianId;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.isAvailable,
    this.technicianId,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      isAvailable: json['isAvailable'] ?? false,
      technicianId: json['technicianId'],
    );
  }

  @override
  List<Object?> get props => [startTime, endTime, isAvailable, technicianId];
}
