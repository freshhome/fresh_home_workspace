// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_updated_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServicesUpdatedRemoteModel _$ServicesUpdatedRemoteModelFromJson(
        Map<String, dynamic> json) =>
    ServicesUpdatedRemoteModel(
      lastUpdatedAt: const TimestampConverter().fromJson(json['lastUpdatedAt']),
      services: (json['services'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, const TimestampConverter().fromJson(e)),
      ),
      subServices: (json['subServices'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(k, const TimestampConverter().fromJson(e)),
      ),
    );

Map<String, dynamic> _$ServicesUpdatedRemoteModelToJson(
        ServicesUpdatedRemoteModel instance) =>
    <String, dynamic>{
      'lastUpdatedAt':
          const TimestampConverter().toJson(instance.lastUpdatedAt),
      'services': instance.services
          .map((k, e) => MapEntry(k, const TimestampConverter().toJson(e))),
      'subServices': instance.subServices
          .map((k, e) => MapEntry(k, const TimestampConverter().toJson(e))),
    };
