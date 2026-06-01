// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_details_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LanguageContentHiveModelAdapter
    extends TypeAdapter<LanguageContentHiveModel> {
  @override
  final int typeId = 7;

  @override
  LanguageContentHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LanguageContentHiveModel(
      title: fields[0] as String?,
      icon: fields[1] as String?,
      points: (fields[2] as List?)?.cast<String>(),
      iconPath: fields[3] as String?,
      iconId: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, LanguageContentHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.title)
      ..writeByte(1)
      ..write(obj.icon)
      ..writeByte(2)
      ..write(obj.points)
      ..writeByte(3)
      ..write(obj.iconPath)
      ..writeByte(4)
      ..write(obj.iconId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LanguageContentHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NotIncludedHiveModelAdapter extends TypeAdapter<NotIncludedHiveModel> {
  @override
  final int typeId = 8;

  @override
  NotIncludedHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return NotIncludedHiveModel(
      ar: fields[0] as LanguageContentHiveModel,
      en: fields[1] as LanguageContentHiveModel,
    );
  }

  @override
  void write(BinaryWriter writer, NotIncludedHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.ar)
      ..writeByte(1)
      ..write(obj.en);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotIncludedHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class DetailHiveModelAdapter extends TypeAdapter<DetailHiveModel> {
  @override
  final int typeId = 11;

  @override
  DetailHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DetailHiveModel(
      id: fields[0] as String?,
      ar: fields[1] as LanguageContentHiveModel,
      en: fields[2] as LanguageContentHiveModel,
    );
  }

  @override
  void write(BinaryWriter writer, DetailHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ar)
      ..writeByte(2)
      ..write(obj.en);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DetailHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
