import 'package:equatable/equatable.dart';

/// Value object encapsulating Governorate domain logic and normalization readiness.
class GovernorateValue extends Equatable {
  final String name;
  final int? id;
  final String? code;

  const GovernorateValue({
    required this.name,
    this.id,
    this.code,
  });

  bool get isValid => name.trim().length >= 2 && name.length <= 100;

  String get sanitizedName => name.trim();

  @override
  List<Object?> get props => [name, id, code];
}
