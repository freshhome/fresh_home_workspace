import 'package:equatable/equatable.dart';

enum DynamicFieldType {
  number,
  toggle,
  dropdown,
  optionsGroup;

  static DynamicFieldType fromString(String value) {
    switch (value) {
      case 'number':
        return DynamicFieldType.number;
      case 'toggle':
        return DynamicFieldType.toggle;
      case 'dropdown':
        return DynamicFieldType.dropdown;
      case 'options_group':
      case 'optionsGroup':
        return DynamicFieldType.optionsGroup;
      default:
        return DynamicFieldType.number;
    }
  }
}

class DropdownOptionEntity extends Equatable {
  final String id;
  final Map<String, String> label;

  const DropdownOptionEntity({required this.id, required this.label});

  @override
  List<Object?> get props => [id, label];
}

class DynamicFieldEntity extends Equatable {
  final String id;
  final DynamicFieldType type;
  final Map<String, String> label;
  final bool required;
  final num? min;
  final String? unit;
  final num? priceModifier;
  final List<DropdownOptionEntity>? options;
  final Map<String, String>? description;
  final String? icon;
  final String? displayType;

  const DynamicFieldEntity({
    required this.id,
    required this.type,
    required this.label,
    this.required = false,
    this.min,
    this.unit,
    this.priceModifier,
    this.options,
    this.description,
    this.icon,
    this.displayType,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        label,
        required,
        min,
        unit,
        priceModifier,
        options,
        description,
        icon,
        displayType,
      ];
}
