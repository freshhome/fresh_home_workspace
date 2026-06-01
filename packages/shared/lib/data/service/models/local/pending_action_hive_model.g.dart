// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_action_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PendingActionHiveModelAdapter
    extends TypeAdapter<PendingActionHiveModel> {
  @override
  final int typeId = 25;

  @override
  PendingActionHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PendingActionHiveModel(
      id: fields[0] as String,
      actionType: fields[1] as String,
      entityType: fields[2] as String,
      payload: fields[3] as String,
      entityId: fields[4] as String,
      createdAt: fields[6] as DateTime,
      mainServiceId: fields[5] as String?,
      retryCount: fields[7] as int,
    );
  }

  @override
  void write(BinaryWriter writer, PendingActionHiveModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.actionType)
      ..writeByte(2)
      ..write(obj.entityType)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.entityId)
      ..writeByte(5)
      ..write(obj.mainServiceId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PendingActionHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
