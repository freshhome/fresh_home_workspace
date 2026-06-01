import 'package:shared/domain/service/enums/service_status.dart';
import 'base_service_entity.dart';
import 'sub_entities/service_price.dart';
import 'sub_entities/service_details.dart';
import 'sub_entities/computed_field.dart';

class ServiceEntity extends BaseServiceEntity {
  final String? parentId;
  final bool isBookable;
  final Map<String, String>? instructions;
  final PriceEntity? price;
  final List<DetailEntity>? details;
  final NotIncludedEntity? notIncluded;
  final List<ComputedFieldEntity>? computedFields;

  const ServiceEntity({
    required super.id,
    this.parentId,
    required this.isBookable,
    required super.title,
    required super.description,
    this.instructions,
    super.image,
    required super.status,
    required super.order,
    required super.updatedAt,
    this.price,
    this.details,
    this.notIncluded,
    this.computedFields,
  });

  @override
  ServiceEntity copyWith({
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
    PriceEntity? price,
    List<DetailEntity>? details,
    NotIncludedEntity? notIncluded,
    List<ComputedFieldEntity>? computedFields,
  }) {
    return ServiceEntity(
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
      price: price ?? this.price,
      details: details ?? this.details,
      notIncluded: notIncluded ?? this.notIncluded,
      computedFields: computedFields ?? this.computedFields,
    );
  }
}
