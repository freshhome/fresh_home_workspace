import 'package:shared/domain/service/entities/service_entity.dart';
import 'package:shared/domain/service/entities/sub_service_entity.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'sub_entities/service_price.dart';
import 'sub_entities/service_details.dart';
import 'sub_entities/computed_field.dart';

class MainServiceEntity extends ServiceEntity {
  final List<SubServiceEntity> subServices;

  const MainServiceEntity({
    required super.id,
    super.parentId,
    super.isBookable = false,
    required super.title,
    required super.description,
    super.instructions,
    super.image,
    required super.status,
    required super.order,
    required super.updatedAt,
    super.computedFields,
    this.subServices = const [],
  });

  @override
  MainServiceEntity copyWith({
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
    List<SubServiceEntity>? subServices,
  }) {
    return MainServiceEntity(
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
      computedFields: computedFields ?? this.computedFields,
      subServices: subServices ?? this.subServices,
    );
  }
}
