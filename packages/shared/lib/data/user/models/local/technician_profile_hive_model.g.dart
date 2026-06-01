// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'technician_profile_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TechnicianProfileHiveModelAdapter
    extends TypeAdapter<TechnicianProfileHiveModel> {
  @override
  final int typeId = 23;

  @override
  TechnicianProfileHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TechnicianProfileHiveModel(
      userId: fields[0] as String,
      bio: fields[1] as String?,
      rating: fields[2] as double,
      completedJobs: fields[3] as int,
      isVerified: fields[4] as bool,
      isAvailable: fields[5] as bool,
      serviceArea: (fields[6] as Map?)?.cast<String, dynamic>(),
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TechnicianProfileHiveModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.bio)
      ..writeByte(2)
      ..write(obj.rating)
      ..writeByte(3)
      ..write(obj.completedJobs)
      ..writeByte(4)
      ..write(obj.isVerified)
      ..writeByte(5)
      ..write(obj.isAvailable)
      ..writeByte(6)
      ..write(obj.serviceArea)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TechnicianProfileHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
