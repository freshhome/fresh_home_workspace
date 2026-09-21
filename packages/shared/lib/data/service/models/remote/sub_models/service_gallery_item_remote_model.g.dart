// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_gallery_item_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceGalleryItemRemoteModel _$ServiceGalleryItemRemoteModelFromJson(
        Map<String, dynamic> json) =>
    ServiceGalleryItemRemoteModel(
      url: json['url'] as String,
      id: json['id'] as String?,
      caption: json['caption'] as String?,
    );

Map<String, dynamic> _$ServiceGalleryItemRemoteModelToJson(
        ServiceGalleryItemRemoteModel instance) =>
    <String, dynamic>{
      'url': instance.url,
      'id': instance.id,
      'caption': instance.caption,
    };
