import 'package:shared/domain/service/enums/service_status.dart';
import 'sub_entities/service_gallery_item.dart';

class BaseServiceEntity {
  final String id;
  final Map<String, String> title;
  final Map<String, String> description;
  final String? image;
  final List<ServiceGalleryItemEntity>? gallery;
  final ServiceStatus status;
  final DateTime updatedAt;
  final int order;

  const BaseServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    this.gallery,
    required this.status,
    required this.updatedAt,
    required this.order,
  });

  BaseServiceEntity copyWith({
    String? id,
    Map<String, String>? title,
    Map<String, String>? description,
    String? image,
    List<ServiceGalleryItemEntity>? gallery,
    ServiceStatus? status,
    DateTime? updatedAt,
    int? order,
  }) {
    return BaseServiceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      gallery: gallery ?? this.gallery,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
    );
  }
}
