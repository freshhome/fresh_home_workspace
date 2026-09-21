import 'package:json_annotation/json_annotation.dart';

part 'service_gallery_item_remote_model.g.dart';

@JsonSerializable()
class ServiceGalleryItemRemoteModel {
  final String url;
  final String? id;
  final String? caption;

  const ServiceGalleryItemRemoteModel({
    required this.url,
    this.id,
    this.caption,
  });

  factory ServiceGalleryItemRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$ServiceGalleryItemRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$ServiceGalleryItemRemoteModelToJson(this);
}
