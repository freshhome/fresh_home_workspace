import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'service_status.g.dart';
// TODO الاينم ده عاوز يتعمل زي user_role
@HiveType(typeId: HiveTypeIds.serviceStatus)
enum ServiceStatus {
  @HiveField(0)
  draft,
  @HiveField(1)
  review,
  @HiveField(2)
  ready,
  @HiveField(3)
  active,
  @HiveField(4)
  paused,
  @HiveField(5)
  archived,
}

extension ServiceStatusX on ServiceStatus {
  String get arabicLabel {
    switch (this) {
      case ServiceStatus.draft:
        return 'مسودة';
      case ServiceStatus.review:
        return 'قيد المراجعة';
      case ServiceStatus.ready:
        return 'جاهز';
      case ServiceStatus.active:
        return 'نشط';
      case ServiceStatus.paused:
        return 'متوقف مؤقتاً';
      case ServiceStatus.archived:
        return 'مؤرشف';
    }
  }
}