import 'package:json_annotation/json_annotation.dart';

part 'computed_field_remote_model.g.dart';

@JsonSerializable()
class ComputedFieldRemoteModel {
  final String? id;
  final String? formula;
  final Map<String, String>? label;

  const ComputedFieldRemoteModel({
    this.id,
    this.formula,
    this.label,
  });

  factory ComputedFieldRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$ComputedFieldRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ComputedFieldRemoteModelToJson(this);
}
