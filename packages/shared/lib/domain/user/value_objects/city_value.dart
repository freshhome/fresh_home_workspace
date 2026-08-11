import 'package:equatable/equatable.dart';

/// Value object encapsulating City domain logic and normalization readiness.
class CityValue extends Equatable {
  final String name;
  final int? id;
  final int? governorateId;

  const CityValue({
    required this.name,
    this.id,
    this.governorateId,
  });

  bool get isValid => name.trim().length >= 2 && name.length <= 100;

  String get sanitizedName => name.trim();

  @override
  List<Object?> get props => [name, id, governorateId];
}
