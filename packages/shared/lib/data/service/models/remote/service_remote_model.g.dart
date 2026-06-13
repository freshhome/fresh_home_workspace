// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceRemoteModel _$ServiceRemoteModelFromJson(Map<String, dynamic> json) =>
    ServiceRemoteModel(
      id: json['id'] as String,
      parentId: json['parent_id'] as String?,
      isBookable: json['is_bookable'] as bool,
      title: Map<String, String>.from(json['title'] as Map),
      description: Map<String, String>.from(json['description'] as Map),
      instructions: (json['instructions'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      image: json['image'] as String?,
      status: $enumDecode(_$ServiceStatusEnumMap, json['status']),
      order: (json['sort_order'] as num).toInt(),
      updatedAt: const TimestampConverter().fromJson(json['updated_at']),
      priceConfig: json['price_config'] == null
          ? null
          : PriceRemoteModel.fromJson(
              json['price_config'] as Map<String, dynamic>),
      details: (json['details'] as List<dynamic>?)
          ?.map((e) => DetailRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      notIncluded: json['not_included'] == null
          ? null
          : NotIncludedRemoteModel.fromJson(
              json['not_included'] as Map<String, dynamic>),
      computedFields: (json['computed_fields'] as List<dynamic>?)
          ?.map((e) =>
              ComputedFieldRemoteModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      commissionRate: (json['commission_rate'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ServiceRemoteModelToJson(ServiceRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'parent_id': instance.parentId,
      'is_bookable': instance.isBookable,
      'title': instance.title,
      'description': instance.description,
      'instructions': instance.instructions,
      'image': instance.image,
      'status': _$ServiceStatusEnumMap[instance.status]!,
      'sort_order': instance.order,
      'updated_at': const TimestampConverter().toJson(instance.updatedAt),
      'price_config': instance.priceConfig?.toJson(),
      'details': instance.details?.map((e) => e.toJson()).toList(),
      'not_included': instance.notIncluded?.toJson(),
      'computed_fields':
          instance.computedFields?.map((e) => e.toJson()).toList(),
      'commission_rate': instance.commissionRate,
    };

const _$ServiceStatusEnumMap = {
  ServiceStatus.draft: 'draft',
  ServiceStatus.review: 'review',
  ServiceStatus.ready: 'ready',
  ServiceStatus.active: 'active',
  ServiceStatus.paused: 'paused',
  ServiceStatus.archived: 'archived',
};
