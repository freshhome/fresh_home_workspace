import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'service_details_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.languageContent)
class LanguageContentHiveModel extends HiveObject {
  @HiveField(0)
  final String? title;
  @HiveField(1)
  final String? icon;
  @HiveField(2)
  final List<String>? points;
  @HiveField(3)
  final String? iconPath;
  @HiveField(4)
  final String? iconId;

  LanguageContentHiveModel({
    this.title,
    this.icon,
    this.points,
    this.iconPath,
    this.iconId,
  });
}

@HiveType(typeId: HiveTypeIds.notIncluded)
class NotIncludedHiveModel extends HiveObject {
  @HiveField(0)
  final LanguageContentHiveModel ar;
  @HiveField(1)
  final LanguageContentHiveModel en;

  NotIncludedHiveModel({
    required this.ar,
    required this.en,
  });
}

@HiveType(typeId: HiveTypeIds.detail)
class DetailHiveModel extends HiveObject {
  @HiveField(0)
  final String? id;
  @HiveField(1)
  final LanguageContentHiveModel ar;
  @HiveField(2)
  final LanguageContentHiveModel en;

  DetailHiveModel({
    this.id,
    required this.ar,
    required this.en,
  });
}
