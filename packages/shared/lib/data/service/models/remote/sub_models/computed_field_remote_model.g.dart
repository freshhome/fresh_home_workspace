// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'computed_field_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComputedFieldRemoteModel _$ComputedFieldRemoteModelFromJson(
        Map<String, dynamic> json) =>
    ComputedFieldRemoteModel(
      id: json['id'] as String?,
      formula: json['formula'] as String?,
      label: (json['label'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
    );

Map<String, dynamic> _$ComputedFieldRemoteModelToJson(
        ComputedFieldRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'formula': instance.formula,
      'label': instance.label,
    };
