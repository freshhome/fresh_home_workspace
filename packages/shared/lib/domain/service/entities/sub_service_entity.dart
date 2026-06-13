import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'sub_entities/service_price.dart';
import 'sub_entities/service_details.dart';
import 'sub_entities/computed_field.dart';

class SubServiceEntity extends ServiceEntity {
  @override
  final PriceEntity price;
  @override
  final NotIncludedEntity notIncluded;
  @override
  final List<DetailEntity> details;

  const SubServiceEntity({
    required super.id,
    super.parentId,
    super.isBookable = true,
    required super.title,
    required super.description,
    super.instructions,
    super.image,
    required super.status,
    required super.order,
    required super.updatedAt,
    super.commissionRate,
    required this.price,
    required this.details,
    required this.notIncluded,
    super.computedFields,
  }) : super(price: price, details: details, notIncluded: notIncluded);

  @override
  SubServiceEntity copyWith({
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
    double? commissionRate,
  }) {
    return SubServiceEntity(
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
      commissionRate: commissionRate ?? this.commissionRate,
      price: price ?? this.price,
      details: details ?? this.details,
      notIncluded: notIncluded ?? this.notIncluded,
      computedFields: computedFields ?? this.computedFields,
    );
  }
}
