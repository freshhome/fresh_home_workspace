import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'services_updated_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.servicesUpdated)
class ServicesUpdatedHiveModel extends HiveObject {
  @HiveField(0)
  final DateTime lastUpdatedAt;

  @HiveField(1)
  final Map<String, DateTime> services;

  @HiveField(2)
  final Map<String, DateTime> subServices;

  ServicesUpdatedHiveModel({
    required this.lastUpdatedAt,
    required this.services,
    required this.subServices,
  });
}
