class ComputedFieldEntity {
  final String id;
  final String formula;
  final Map<String, String> label;

  const ComputedFieldEntity({
    required this.id,
    required this.formula,
    required this.label,
  });

  ComputedFieldEntity copyWith({
    String? id,
    String? formula,
    Map<String, String>? label,
  }) {
    return ComputedFieldEntity(
      id: id ?? this.id,
      formula: formula ?? this.formula,
      label: label ?? this.label,
    );
  }
}
