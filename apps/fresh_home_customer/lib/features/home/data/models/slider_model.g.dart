// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slider_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SliderModel _$SliderModelFromJson(Map<String, dynamic> json) => SliderModel(
  image: json['image'] as String,
  serviceId: json['serviceId'] as String,
  order: (json['order'] as num).toInt(),
);

Map<String, dynamic> _$SliderModelToJson(SliderModel instance) =>
    <String, dynamic>{
      'image': instance.image,
      'serviceId': instance.serviceId,
      'order': instance.order,
    };
