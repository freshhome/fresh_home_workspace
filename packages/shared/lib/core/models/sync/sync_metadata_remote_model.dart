import 'package:json_annotation/json_annotation.dart';
import 'package:shared/core/converters/timestamp_converter.dart';

part 'sync_metadata_remote_model.g.dart';

@JsonSerializable()
@TimestampConverter()
class SyncMetadataRemoteModel {

  final String collectionName;
  final DateTime lastUpdatedAt;

  const SyncMetadataRemoteModel({
    required this.collectionName,
    required this.lastUpdatedAt,
  });

  factory SyncMetadataRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$SyncMetadataRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$SyncMetadataRemoteModelToJson(this);
}
