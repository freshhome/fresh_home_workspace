import 'package:equatable/equatable.dart';
import '../../domain/entities/pricing_rule_entity.dart';
import '../../domain/entities/pricing_discount_entity.dart';
import '../../domain/entities/pricing_version_entity.dart';

abstract class PricingGovernanceState extends Equatable {
  const PricingGovernanceState();

  @override
  List<Object?> get props => [];
}

class PricingGovernanceInitial extends PricingGovernanceState {}

class PricingGovernanceLoading extends PricingGovernanceState {}

class PricingGovernanceLoaded extends PricingGovernanceState {
  final List<PricingRuleEntity> rules;
  final List<PricingDiscountEntity> discounts;
  final List<PricingVersionEntity> versions;
  final List<Map<String, dynamic>> auditLogs;

  const PricingGovernanceLoaded({
    required this.rules,
    required this.discounts,
    required this.versions,
    required this.auditLogs,
  });

  @override
  List<Object?> get props => [rules, discounts, versions, auditLogs];

  PricingGovernanceLoaded copyWith({
    List<PricingRuleEntity>? rules,
    List<PricingDiscountEntity>? discounts,
    List<PricingVersionEntity>? versions,
    List<Map<String, dynamic>>? auditLogs,
  }) {
    return PricingGovernanceLoaded(
      rules: rules ?? this.rules,
      discounts: discounts ?? this.discounts,
      versions: versions ?? this.versions,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }
}

class PricingGovernanceFailure extends PricingGovernanceState {
  final String message;

  const PricingGovernanceFailure(this.message);

  @override
  List<Object?> get props => [message];
}

class BookingReplaySuccess extends PricingGovernanceState {
  final Map<String, dynamic> replayResult;

  const BookingReplaySuccess(this.replayResult);

  @override
  List<Object?> get props => [replayResult];
}

class PricingSimulationSuccess extends PricingGovernanceState {
  final Map<String, dynamic> simulationResult;

  const PricingSimulationSuccess(this.simulationResult);

  @override
  List<Object?> get props => [simulationResult];
}
