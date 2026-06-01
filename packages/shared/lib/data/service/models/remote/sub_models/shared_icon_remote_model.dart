import 'package:json_annotation/json_annotation.dart';
import 'package:shared/domain/service/entities/sub_entities/shared_icon_entity.dart';

part 'shared_icon_remote_model.g.dart';

@JsonSerializable(explicitToJson: true)
class SharedIconRemoteModel {
  final String id;
  final Map<String, String> name;
  @JsonKey(name: 'storage_path')
  final String storagePath;
  @JsonKey(name: 'public_url')
  final String publicUrl;
  final String category;
  @JsonKey(name: 'usage_count')
  final int usageCount;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const SharedIconRemoteModel({
    required this.id,
    required this.name,
    required this.storagePath,
    required this.publicUrl,
    required this.category,
    required this.usageCount,
    this.createdAt,
  });

  factory SharedIconRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$SharedIconRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$SharedIconRemoteModelToJson(this);

  SharedIconEntity toEntity() {
    return SharedIconEntity(
      id: id,
      name: name,
      storagePath: storagePath,
      publicUrl: publicUrl,
      category: category,
      usageCount: usageCount,
      createdAt: createdAt,
    );
  }

  factory SharedIconRemoteModel.fromEntity(SharedIconEntity entity) {
    return SharedIconRemoteModel(
      id: entity.id,
      name: entity.name,
      storagePath: entity.storagePath,
      publicUrl: entity.publicUrl,
      category: entity.category,
      usageCount: entity.usageCount,
      createdAt: entity.createdAt,
    );
  }
}
