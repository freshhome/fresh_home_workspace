// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_details_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LanguageContentRemoteModel _$LanguageContentRemoteModelFromJson(
        Map<String, dynamic> json) =>
    LanguageContentRemoteModel(
      title: json['title'] as String?,
      icon: json['icon'] as String?,
      iconPath: json['icon_path'] as String?,
      iconId: json['icon_id'] as String?,
      points:
          (json['points'] as List<dynamic>?)?.map((e) => e as String).toList(),
    );

Map<String, dynamic> _$LanguageContentRemoteModelToJson(
        LanguageContentRemoteModel instance) =>
    <String, dynamic>{
      'title': instance.title,
      'icon': instance.icon,
      'icon_path': instance.iconPath,
      'icon_id': instance.iconId,
      'points': instance.points,
    };

NotIncludedRemoteModel _$NotIncludedRemoteModelFromJson(
        Map<String, dynamic> json) =>
    NotIncludedRemoteModel(
      ar: json['ar'] == null
          ? null
          : LanguageContentRemoteModel.fromJson(
              json['ar'] as Map<String, dynamic>),
      en: json['en'] == null
          ? null
          : LanguageContentRemoteModel.fromJson(
              json['en'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$NotIncludedRemoteModelToJson(
        NotIncludedRemoteModel instance) =>
    <String, dynamic>{
      'ar': instance.ar?.toJson(),
      'en': instance.en?.toJson(),
    };

DetailRemoteModel _$DetailRemoteModelFromJson(Map<String, dynamic> json) =>
    DetailRemoteModel(
      id: json['id'] as String?,
      ar: LanguageContentRemoteModel.fromJson(
          json['ar'] as Map<String, dynamic>),
      en: LanguageContentRemoteModel.fromJson(
          json['en'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$DetailRemoteModelToJson(DetailRemoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'ar': instance.ar.toJson(),
      'en': instance.en.toJson(),
    };
