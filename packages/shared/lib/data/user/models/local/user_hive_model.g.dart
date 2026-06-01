// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserHiveModelAdapter extends TypeAdapter<UserHiveModel> {
  @override
  final int typeId = 14;

  @override
  UserHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserHiveModel(
      customId: fields[0] as int,
      uid: fields[1] as String,
      firstName: fields[2] as String,
      lastName: fields[3] as String,
      email: fields[4] as String,
      accountStatus: fields[5] as String,
      gender: fields[6] as String,
      avatarUrl: fields[10] as String?,
      rolesCodes: (fields[7] as List).cast<int>(),
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      phones: (fields[11] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, UserHiveModel obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.customId)
      ..writeByte(1)
      ..write(obj.uid)
      ..writeByte(2)
      ..write(obj.firstName)
      ..writeByte(3)
      ..write(obj.lastName)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.accountStatus)
      ..writeByte(6)
      ..write(obj.gender)
      ..writeByte(10)
      ..write(obj.avatarUrl)
      ..writeByte(7)
      ..write(obj.rolesCodes)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(11)
      ..write(obj.phones);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
