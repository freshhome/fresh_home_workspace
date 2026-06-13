// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceHiveModelAdapter extends TypeAdapter<ServiceHiveModel> {
  @override
  final int typeId = 4;

  @override
  ServiceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceHiveModel(
      id: fields[0] as String,
      parentId: fields[1] as String?,
      isBookable: fields[2] as bool,
      title: (fields[3] as Map).cast<String, String>(),
      description: (fields[4] as Map).cast<String, String>(),
      instructions: (fields[5] as Map?)?.cast<String, String>(),
      image: fields[6] as String?,
      status: fields[7] as ServiceStatus,
      order: fields[8] as int,
      updatedAt: fields[9] as DateTime,
      price: fields[10] as PriceHiveModel?,
      details: (fields[11] as List?)?.cast<DetailHiveModel>(),
      notIncluded: fields[12] as NotIncludedHiveModel?,
      computedFields: (fields[13] as List?)?.cast<dynamic>(),
      commissionRate: fields[14] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceHiveModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.parentId)
      ..writeByte(2)
      ..write(obj.isBookable)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.instructions)
      ..writeByte(6)
      ..write(obj.image)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.order)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.price)
      ..writeByte(11)
      ..write(obj.details)
      ..writeByte(12)
      ..write(obj.notIncluded)
      ..writeByte(13)
      ..write(obj.computedFields)
      ..writeByte(14)
      ..write(obj.commissionRate);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
