import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'service_gallery_item_hive_model.g.dart';

@HiveType(typeId: HiveTypeIds.serviceGalleryItem)
class ServiceGalleryItemHiveModel extends HiveObject {
  @HiveField(0)
  final String url;

  @HiveField(1)
  final String? id;

  @HiveField(2)
  final String? caption;

  ServiceGalleryItemHiveModel({
    required this.url,
    this.id,
    this.caption,
  });
}
