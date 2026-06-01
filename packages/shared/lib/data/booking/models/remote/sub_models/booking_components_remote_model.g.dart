// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_components_remote_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookedServiceModel _$BookedServiceModelFromJson(Map<String, dynamic> json) =>
    BookedServiceModel(
      id: json['id'] as String,
      subServiceId: json['subServiceId'] as String,
      name: Map<String, String>.from(json['name'] as Map),
      image: json['image'] as String,
    );

Map<String, dynamic> _$BookedServiceModelToJson(BookedServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subServiceId': instance.subServiceId,
      'name': instance.name,
      'image': instance.image,
    };

BookingPricingModel _$BookingPricingModelFromJson(Map<String, dynamic> json) =>
    BookingPricingModel(
      basePrice: (json['basePrice'] as num).toDouble(),
      extraFees: (json['extraFees'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
    );

Map<String, dynamic> _$BookingPricingModelToJson(
        BookingPricingModel instance) =>
    <String, dynamic>{
      'basePrice': instance.basePrice,
      'extraFees': instance.extraFees,
      'discount': instance.discount,
      'total': instance.total,
    };

ContactModel _$ContactModelFromJson(Map<String, dynamic> json) => ContactModel(
      name: json['name'] as String,
      phone: (json['phone'] as List<dynamic>).map((e) => e as String).toList(),
    );

Map<String, dynamic> _$ContactModelToJson(ContactModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'phone': instance.phone,
    };

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    ScheduleModel(
      day: json['day'] as String,
      time: json['time'] as String,
    );

Map<String, dynamic> _$ScheduleModelToJson(ScheduleModel instance) =>
    <String, dynamic>{
      'day': instance.day,
      'time': instance.time,
    };
