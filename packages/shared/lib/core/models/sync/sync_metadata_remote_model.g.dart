// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncMetadataRemoteModel _$SyncMetadataRemoteModelFromJson(
        Map<String, dynamic> json) =>
    SyncMetadataRemoteModel(
      collectionName: json['collectionName'] as String,
      lastUpdatedAt: const TimestampConverter().fromJson(json['lastUpdatedAt']),
    );

Map<String, dynamic> _$SyncMetadataRemoteModelToJson(
        SyncMetadataRemoteModel instance) =>
    <String, dynamic>{
      'collectionName': instance.collectionName,
      'lastUpdatedAt':
          const TimestampConverter().toJson(instance.lastUpdatedAt),
    };
