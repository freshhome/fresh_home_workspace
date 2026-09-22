import 'package:equatable/equatable.dart';

enum DynamicFieldType {
  number,
  toggle,
  dropdown,
  optionsGroup,
  linearSectors;

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
      case 'linear_sectors':
      case 'linearSectors':
      case 'window_sectors':
      case 'windowSectors':
        return DynamicFieldType.linearSectors;
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
  final Map<String, String>? hint;
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
    this.hint,
    this.required = false,
    this.min,
    this.unit,
    this.priceModifier,
    this.options,
    this.description,
    this.icon,
    this.displayType,
  });

  /// Returns localized hint if present and non-empty;
  /// otherwise cleanly falls back to the localized label.
  String resolveHint(String locale) {
    final locHint = hint?[locale]?.trim();
    if (locHint != null && locHint.isNotEmpty) return locHint;

    final arHint = hint?['ar']?.trim();
    if (arHint != null && arHint.isNotEmpty) return arHint;

    final locLabel = label[locale]?.trim();
    if (locLabel != null && locLabel.isNotEmpty) return locLabel;

    final arLabel = label['ar']?.trim();
    if (arLabel != null && arLabel.isNotEmpty) return arLabel;

    return id;
  }

  @override
  List<Object?> get props => [
        id,
        type,
        label,
        hint,
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
