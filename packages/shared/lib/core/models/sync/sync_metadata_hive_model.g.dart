// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_metadata_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncMetadataHiveModelAdapter extends TypeAdapter<SyncMetadataHiveModel> {
  @override
  final int typeId = 6;

  @override
  SyncMetadataHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMetadataHiveModel(
      collectionName: fields[0] as String,
      lastUpdatedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMetadataHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.collectionName)
      ..writeByte(1)
      ..write(obj.lastUpdatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMetadataHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
