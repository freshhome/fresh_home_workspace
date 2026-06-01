// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_snapshots.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServiceSnapshotModel _$ServiceSnapshotModelFromJson(
        Map<String, dynamic> json) =>
    ServiceSnapshotModel(
      id: json['id'] as String,
      subServiceId: json['subServiceId'] as String,
      name: Map<String, String>.from(json['name'] as Map),
      image: json['image'] as String,
    );

Map<String, dynamic> _$ServiceSnapshotModelToJson(
        ServiceSnapshotModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'subServiceId': instance.subServiceId,
      'name': instance.name,
      'image': instance.image,
    };

AddressSnapshotModel _$AddressSnapshotModelFromJson(
        Map<String, dynamic> json) =>
    AddressSnapshotModel(
      governorate: json['governorate'] as String,
      city: json['city'] as String,
      street: json['street'] as String,
      buildingNumber: json['buildingNumber'] as String,
      apartmentNumber: json['apartmentNumber'] as String?,
      floorNumber: json['floorNumber'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AddressSnapshotModelToJson(
        AddressSnapshotModel instance) =>
    <String, dynamic>{
      'governorate': instance.governorate,
      'city': instance.city,
      'street': instance.street,
      'buildingNumber': instance.buildingNumber,
      'apartmentNumber': instance.apartmentNumber,
      'floorNumber': instance.floorNumber,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

PriceSnapshotModel _$PriceSnapshotModelFromJson(Map<String, dynamic> json) =>
    PriceSnapshotModel(
      basePrice: (json['basePrice'] as num).toDouble(),
      extraFees: (json['extraFees'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      metadata: json['metadata'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PriceSnapshotModelToJson(PriceSnapshotModel instance) =>
    <String, dynamic>{
      'basePrice': instance.basePrice,
      'extraFees': instance.extraFees,
      'discount': instance.discount,
      'total': instance.total,
      'metadata': instance.metadata,
    };
