// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_profile_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ClientProfileHiveModelAdapter
    extends TypeAdapter<ClientProfileHiveModel> {
  @override
  final int typeId = 15;

  @override
  ClientProfileHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ClientProfileHiveModel(
      uid: fields[0] as String,
      addresses: (fields[1] as List).cast<AddressModel>(),
      phoneNumbers: (fields[2] as List).cast<PhoneModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, ClientProfileHiveModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.addresses)
      ..writeByte(2)
      ..write(obj.phoneNumbers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClientProfileHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
