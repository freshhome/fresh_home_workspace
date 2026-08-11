import 'package:equatable/equatable.dart';

/// Value object encapsulating District domain logic and normalization readiness.
class DistrictValue extends Equatable {
  final String name;
  final int? id;
  final int? cityId;

  const DistrictValue({
    required this.name,
    this.id,
    this.cityId,
  });

  bool get isValid => name.trim().length >= 2 && name.length <= 100;

  String get sanitizedName => name.trim();

  @override
  List<Object?> get props => [name, id, cityId];
}
