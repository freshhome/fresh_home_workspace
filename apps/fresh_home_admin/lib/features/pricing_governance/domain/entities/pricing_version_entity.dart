import 'package:equatable/equatable.dart';

class PricingVersionEntity extends Equatable {
  final String id;
  final String subServiceId;
  final Map<String, dynamic> snapshot;
  final DateTime createdAt;
  final bool isActive;

  const PricingVersionEntity({
    required this.id,
    required this.subServiceId,
    required this.snapshot,
    required this.createdAt,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
        id,
        subServiceId,
        snapshot,
        createdAt,
        isActive,
      ];
}
