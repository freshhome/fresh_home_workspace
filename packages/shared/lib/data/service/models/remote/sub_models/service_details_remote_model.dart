import 'package:json_annotation/json_annotation.dart';

part 'service_details_remote_model.g.dart';

@JsonSerializable()
class LanguageContentRemoteModel {
  final String? title;
  final String? icon;
  @JsonKey(name: 'icon_path')
  final String? iconPath;
  @JsonKey(name: 'icon_id')
  final String? iconId;
  final List<String>? points;

  const LanguageContentRemoteModel({
    this.title,
    this.icon,
    this.iconPath,
    this.iconId,
    this.points,
  });

  factory LanguageContentRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$LanguageContentRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$LanguageContentRemoteModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class NotIncludedRemoteModel {
  final LanguageContentRemoteModel? ar;
  final LanguageContentRemoteModel? en;

  const NotIncludedRemoteModel({
    this.ar,
    this.en,
  });

  factory NotIncludedRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$NotIncludedRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$NotIncludedRemoteModelToJson(this);
}

@JsonSerializable(explicitToJson: true)
class DetailRemoteModel {
  final String? id;
  final LanguageContentRemoteModel ar;
  final LanguageContentRemoteModel en;

  const DetailRemoteModel({
    this.id,
    required this.ar,
    required this.en,
  });

  factory DetailRemoteModel.fromJson(Map<String, dynamic> json) =>
      _$DetailRemoteModelFromJson(json);

  Map<String, dynamic> toJson() => _$DetailRemoteModelToJson(this);
}
