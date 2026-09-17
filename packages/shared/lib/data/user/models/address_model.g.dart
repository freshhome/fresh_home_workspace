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
      governorateId: fields[13] as int?,
      cityId: fields[14] as int?,
      districtId: fields[15] as int?,
      addressDetails: fields[5] as String,
      locationUrl: fields[6] as String?,
      latitude: fields[7] as double?,
      longitude: fields[8] as double?,
      isPrimary: fields[9] as bool,
      deletedAt: fields[10] as DateTime?,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, AddressModel obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.addressDetails)
      ..writeByte(6)
      ..write(obj.locationUrl)
      ..writeByte(7)
      ..write(obj.latitude)
      ..writeByte(8)
      ..write(obj.longitude)
      ..writeByte(9)
      ..write(obj.isPrimary)
      ..writeByte(10)
      ..write(obj.deletedAt)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt)
      ..writeByte(13)
      ..write(obj.governorateId)
      ..writeByte(14)
      ..write(obj.cityId)
      ..writeByte(15)
      ..write(obj.districtId);
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
