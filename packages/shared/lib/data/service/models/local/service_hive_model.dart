import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/service/enums/service_status.dart';
import 'sub_models/service_details_hive_model.dart';
import 'sub_models/service_price_hive_model.dart';

part 'service_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.service)
class ServiceHiveModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? parentId;

  @HiveField(2)
  final bool isBookable;

  @HiveField(3)
  final Map<String, String> title;

  @HiveField(4)
  final Map<String, String> description;

  @HiveField(5)
  final Map<String, String>? instructions;

  @HiveField(6)
  final String? image;

  @HiveField(7)
  final ServiceStatus status;

  @HiveField(8)
  final int order;

  @HiveField(9)
  final DateTime updatedAt;

  @HiveField(10)
  final PriceHiveModel? price;

  @HiveField(11)
  final List<DetailHiveModel>? details;

  @HiveField(12)
  final NotIncludedHiveModel? notIncluded;

  @HiveField(13)
  final List<dynamic>? computedFields;

  @HiveField(14)
  final double? commissionRate;

  ServiceHiveModel({
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
    this.price,
    this.details,
    this.notIncluded,
    this.computedFields,
    this.commissionRate,
  });
}
