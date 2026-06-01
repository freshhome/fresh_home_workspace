import 'package:equatable/equatable.dart';

class PricingRuleEntity extends Equatable {
  final String id;
  final String subServiceId;
  final String ruleName;
  final Map<String, dynamic> conditionAst;
  final String actionType;
  final double actionValue;
  final String actionTarget;
  final int priority;
  final bool isActive;

  const PricingRuleEntity({
    required this.id,
    required this.subServiceId,
    required this.ruleName,
    required this.conditionAst,
    required this.actionType,
    required this.actionValue,
    required this.actionTarget,
    required this.priority,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    subServiceId,
    ruleName,
    conditionAst,
    actionType,
    actionValue,
    actionTarget,
    priority,
    isActive,
  ];
}
