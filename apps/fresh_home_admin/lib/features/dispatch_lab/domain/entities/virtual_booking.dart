import 'package:equatable/equatable.dart';

class VirtualBooking extends Equatable {
  final String id;
  final int sequenceNumber; // e.g. 1, 2, 3...
  final String serviceName;
  final int requiredCapacity;
  final DateTime createdAt;

  const VirtualBooking({
    required this.id,
    required this.sequenceNumber,
    required this.serviceName,
    this.requiredCapacity = 1,
    required this.createdAt,
  });

  factory VirtualBooking.fromJson(Map<String, dynamic> json) {
    return VirtualBooking(
      id: json['id'] as String,
      sequenceNumber: json['sequenceNumber'] as int,
      serviceName: json['serviceName'] as String,
      requiredCapacity: json['requiredCapacity'] as int? ?? 1,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sequenceNumber': sequenceNumber,
      'serviceName': serviceName,
      'requiredCapacity': requiredCapacity,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        sequenceNumber,
        serviceName,
        requiredCapacity,
        createdAt,
      ];
}
