// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_updated_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServicesUpdatedHiveModelAdapter
    extends TypeAdapter<ServicesUpdatedHiveModel> {
  @override
  final int typeId = 22;

  @override
  ServicesUpdatedHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServicesUpdatedHiveModel(
      lastUpdatedAt: fields[0] as DateTime,
      services: (fields[1] as Map).cast<String, DateTime>(),
      subServices: (fields[2] as Map).cast<String, DateTime>(),
    );
  }

  @override
  void write(BinaryWriter writer, ServicesUpdatedHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.lastUpdatedAt)
      ..writeByte(1)
      ..write(obj.services)
      ..writeByte(2)
      ..write(obj.subServices);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServicesUpdatedHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
