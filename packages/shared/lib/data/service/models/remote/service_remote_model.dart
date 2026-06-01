import 'package:json_annotation/json_annotation.dart';
import 'package:shared/core/converters/timestamp_converter.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'sub_models/service_details_remote_model.dart';
import 'sub_models/service_price_remote_model.dart';
import 'sub_models/computed_field_remote_model.dart';

part 'service_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
@TimestampConverter()
class ServiceRemoteModel {
  final String id;
  @JsonKey(name: 'parent_id')
  final String? parentId;
  @JsonKey(name: 'is_bookable')
  final bool isBookable;
  final Map<String, String> title;
  final Map<String, String> description;
  final Map<String, String>? instructions;
  final String? image;
  final ServiceStatus status;
  @JsonKey(name: 'sort_order')
  final int order;
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;
  @JsonKey(name: 'price_config')
  final PriceRemoteModel? priceConfig;
  final List<DetailRemoteModel>? details;
  @JsonKey(name: 'not_included')
  final NotIncludedRemoteModel? notIncluded;
  @JsonKey(name: 'computed_fields')
  final List<ComputedFieldRemoteModel>? computedFields;

  const ServiceRemoteModel({
    required this.id,
    this.parentId,
    required this.isBookable,
    required this.title,
    required this.description,
    this.instructions,
    this.image,
    required this.status,
    required this.order,
    required this.updatedAt,
    this.priceConfig,
    this.details,
    this.notIncluded,
    this.computedFields,
  });

  factory ServiceRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceRemoteModelToJson(this);

  ServiceRemoteModel copyWith({
    String? id,
    String? parentId,
    bool? isBookable,
    Map<String, String>? title,
    Map<String, String>? description,
    Map<String, String>? instructions,
    String? image,
    ServiceStatus? status,
    int? order,
    DateTime? updatedAt,
    PriceRemoteModel? priceConfig,
    List<DetailRemoteModel>? details,
    NotIncludedRemoteModel? notIncluded,
    List<ComputedFieldRemoteModel>? computedFields,
  }) {
    return ServiceRemoteModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      isBookable: isBookable ?? this.isBookable,
      title: title ?? this.title,
      description: description ?? this.description,
      instructions: instructions ?? this.instructions,
      image: image ?? this.image,
      status: status ?? this.status,
      order: order ?? this.order,
      updatedAt: updatedAt ?? this.updatedAt,
      priceConfig: priceConfig ?? this.priceConfig,
      details: details ?? this.details,
      notIncluded: notIncluded ?? this.notIncluded,
      computedFields: computedFields ?? this.computedFields,
    );
  }
}
