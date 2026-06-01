// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AddressModelAdapter extends TypeAdapter<AddressModel> {
  @override
  final int typeId = 16;

  @override
  AddressModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AddressModel(
      id: fields[6] as String?,
      governorate: fields[0] as String,
      city: fields[1] as String,
      street: fields[2] as String,
      buildingNumber: fields[3] as String,
      apartmentNumber: fields[4] as String?,
      floorNumber: fields[5] as String?,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, AddressModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.governorate)
      ..writeByte(1)
      ..write(obj.city)
      ..writeByte(2)
      ..write(obj.street)
      ..writeByte(3)
      ..write(obj.buildingNumber)
      ..writeByte(4)
      ..write(obj.apartmentNumber)
      ..writeByte(5)
      ..write(obj.floorNumber)
      ..writeByte(6)
      ..write(obj.id)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AddressModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AddressModel _$AddressModelFromJson(Map<String, dynamic> json) => AddressModel(
      id: json['id'] as String?,
      governorate: json['governorate'] as String,
      city: json['city'] as String,
      street: json['street'] as String,
      buildingNumber: json['building_number'] as String,
      apartmentNumber: json['apartment'] as String?,
      floorNumber: json['floor'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$AddressModelToJson(AddressModel instance) {
  final val = <String, dynamic>{
    'governorate': instance.governorate,
    'city': instance.city,
    'street': instance.street,
    'building_number': instance.buildingNumber,
    'apartment': instance.apartmentNumber,
    'floor': instance.floorNumber,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['latitude'] = instance.latitude;
  val['longitude'] = instance.longitude;
  return val;
}
