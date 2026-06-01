import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';

part 'sync_metadata_hive_model.g.dart';
@HiveType(typeId: HiveTypeIds.syncMetadata)
class SyncMetadataHiveModel extends HiveObject {
  @HiveField(0)
  final String collectionName;

  @HiveField(1)
  final DateTime lastUpdatedAt;

  SyncMetadataHiveModel({
    required this.collectionName,
    required this.lastUpdatedAt,
  });
}
