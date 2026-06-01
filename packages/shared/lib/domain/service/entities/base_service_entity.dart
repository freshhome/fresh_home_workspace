
import 'package:shared/domain/service/enums/service_status.dart';


class BaseServiceEntity {
  final String id;
  final Map<String, String> title;
  final Map<String, String> description;
  final String? image;
  final ServiceStatus status;
  final DateTime updatedAt;
  final int order;

  const BaseServiceEntity({
    required this.id,
    required this.title,
    required this.description,
    this.image,
    required this.status,
    required this.updatedAt,
    required this.order,
  });

  BaseServiceEntity copyWith({
    String? id,
    Map<String, String>? title,
    Map<String, String>? description,
    String? image,
    ServiceStatus? status,
    DateTime? updatedAt,
    int? order,
  }) {
    return BaseServiceEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      image: image ?? this.image,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
      order: order ?? this.order,
    );
  }
}
