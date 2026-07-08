import 'package:equatable/equatable.dart';

class SnapshotOption extends Equatable {
  final String id;
  final Map<String, String> label;

  const SnapshotOption({
    required this.id,
    required this.label,
  });

  @override
  List<Object?> get props => [id, label];

  factory SnapshotOption.fromJson(Map<String, dynamic> json) {
    return SnapshotOption(
      id: json['id'] as String,
      label: Map<String, String>.from(json['label'] as Map),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
    };
  }
}

class SnapshotField extends Equatable {
  final String id;
  final String type;
  final Map<String, String> label;
  final Map<String, String>? unit;
  final bool required;
  final double? min;
  final double? max;
  final double? step;
  final String? icon;
  final int? displayOrder;
  final List<SnapshotOption>? options;

  const SnapshotField({
    required this.id,
    required this.type,
    required this.label,
    this.unit,
    this.required = false,
    this.min,
    this.max,
    this.step,
    this.icon,
    this.displayOrder,
    this.options,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        label,
        unit,
        required,
        min,
        max,
        step,
        icon,
        displayOrder,
        options,
      ];

  factory SnapshotField.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    List<SnapshotOption>? resolvedOptions;
    if (rawOptions is List) {
      resolvedOptions = rawOptions
          .map((opt) => SnapshotOption.fromJson(Map<String, dynamic>.from(opt as Map)))
          .toList();
    } else if (rawOptions is Map) {
      resolvedOptions = rawOptions.entries
          .map((e) => SnapshotOption.fromJson({
                'id': e.key,
                'label': e.value,
              }))
          .toList();
    }

    return SnapshotField(
      id: json['id'] as String,
      type: json['type'] as String,
      label: Map<String, String>.from(json['label'] as Map),
      unit: json['unit'] != null ? Map<String, String>.from(json['unit'] as Map) : null,
      required: json['required'] as bool? ?? false,
      min: (json['min'] as num?)?.toDouble(),
      max: (json['max'] as num?)?.toDouble(),
      step: (json['step'] as num?)?.toDouble(),
      icon: json['icon'] as String?,
      displayOrder: json['displayOrder'] as int? ?? json['display_order'] as int?,
      options: resolvedOptions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'label': label,
      if (unit != null) 'unit': unit,
      'required': required,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (step != null) 'step': step,
      if (icon != null) 'icon': icon,
      if (displayOrder != null) 'displayOrder': displayOrder,
      if (options != null) 'options': options!.map((opt) => opt.toJson()).toList(),
    };
  }
}

class DynamicFieldSnapshot extends Equatable {
  final int snapshotVersion;
  final DateTime snapshotTimestamp;
  final List<SnapshotField> fields;

  const DynamicFieldSnapshot({
    required this.snapshotVersion,
    required this.snapshotTimestamp,
    required this.fields,
  });

  @override
  List<Object?> get props => [snapshotVersion, snapshotTimestamp, fields];

  factory DynamicFieldSnapshot.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    List<SnapshotField> resolvedFields = [];
    if (rawFields is List) {
      resolvedFields = rawFields
          .map((f) => SnapshotField.fromJson(Map<String, dynamic>.from(f as Map)))
          .toList();
    } else if (rawFields is Map) {
      resolvedFields = rawFields.entries
          .map((e) {
            final fieldMap = Map<String, dynamic>.from(e.value as Map);
            fieldMap['id'] ??= e.key;
            return SnapshotField.fromJson(fieldMap);
          })
          .toList();
    }

    final rawTimestamp = json['snapshotTimestamp'] ?? json['snapshot_timestamp'];
    final timestamp = rawTimestamp != null
        ? DateTime.parse(rawTimestamp as String).toUtc()
        : DateTime.now().toUtc();

    return DynamicFieldSnapshot(
      snapshotVersion: json['snapshotVersion'] as int? ?? json['snapshot_version'] as int? ?? 1,
      snapshotTimestamp: timestamp,
      fields: resolvedFields,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshotVersion': snapshotVersion,
      'snapshotTimestamp': snapshotTimestamp.toIso8601String(),
      'fields': fields.map((f) => f.toJson()).toList(),
    };
  }
}
