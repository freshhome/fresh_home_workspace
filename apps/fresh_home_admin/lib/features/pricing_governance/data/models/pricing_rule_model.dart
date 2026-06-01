import '../../domain/entities/pricing_rule_entity.dart';

class PricingRuleModel extends PricingRuleEntity {
  const PricingRuleModel({
    required super.id,
    required super.subServiceId,
    required super.ruleName,
    required super.conditionAst,
    required super.actionType,
    required super.actionValue,
    required super.actionTarget,
    required super.priority,
    required super.isActive,
  });

  factory PricingRuleModel.fromJson(Map<String, dynamic> json) {
    return PricingRuleModel(
      id: json['id'] as String? ?? '',
      subServiceId: json['sub_service_id'] as String? ?? '',
      ruleName: json['name'] as String? ?? '',
      conditionAst: Map<String, dynamic>.from(
        json['condition_ast'] as Map? ?? {},
      ),
      actionType: json['action_type'] as String? ?? 'multiply',
      actionValue: (json['action_value'] as num?)?.toDouble() ?? 1.0,
      actionTarget: json['action_target'] as String? ?? 'subtotal',
      priority: json['priority'] as int? ?? 1,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_service_id': subServiceId,
      'name': ruleName,
      'condition_ast': conditionAst,
      'action_type': actionType,
      'action_value': actionValue,
      'action_target': actionTarget,
      'priority': priority,
      'is_active': isActive,
    };
  }
}
