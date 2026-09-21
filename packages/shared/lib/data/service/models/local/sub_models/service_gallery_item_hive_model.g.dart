// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_gallery_item_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceGalleryItemHiveModelAdapter
    extends TypeAdapter<ServiceGalleryItemHiveModel> {
  @override
  final int typeId = 26;

  @override
  ServiceGalleryItemHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ServiceGalleryItemHiveModel(
      url: fields[0] as String,
      id: fields[1] as String?,
      caption: fields[2] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ServiceGalleryItemHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.url)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.caption);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceGalleryItemHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
