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
      id: fields[0] as String,
      userId: fields[1] as String,
      governorate: fields[2] as String,
      city: fields[3] as String,
      district: fields[4] as String,
      streetOrCompound: fields[5] as String,
      buildingIdentifier: fields[6] as String,
      floor: fields[7] as String?,
      apartmentOrUnit: fields[8] as String?,
      landmark: fields[9] as String?,
      latitude: fields[10] as double?,
      longitude: fields[11] as double?,
      isPrimary: fields[12] as bool,
      deletedAt: fields[13] as DateTime?,
      createdAt: fields[14] as DateTime,
      updatedAt: fields[15] as DateTime,
      propertyType: fields[16] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AddressModel obj) {
    writer
      ..writeByte(17)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.governorate)
      ..writeByte(3)
      ..write(obj.city)
      ..writeByte(4)
      ..write(obj.district)
      ..writeByte(5)
      ..write(obj.streetOrCompound)
      ..writeByte(6)
      ..write(obj.buildingIdentifier)
      ..writeByte(7)
      ..write(obj.floor)
      ..writeByte(8)
      ..write(obj.apartmentOrUnit)
      ..writeByte(9)
      ..write(obj.landmark)
      ..writeByte(10)
      ..write(obj.latitude)
      ..writeByte(11)
      ..write(obj.longitude)
      ..writeByte(12)
      ..write(obj.isPrimary)
      ..writeByte(13)
      ..write(obj.deletedAt)
      ..writeByte(14)
      ..write(obj.createdAt)
      ..writeByte(15)
      ..write(obj.updatedAt)
      ..writeByte(16)
      ..write(obj.propertyType);
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
