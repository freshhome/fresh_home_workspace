// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'phone_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PhoneModelAdapter extends TypeAdapter<PhoneModel> {
  @override
  final int typeId = 24;

  @override
  PhoneModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PhoneModel(
      id: fields[0] as String?,
      userId: fields[1] as String,
      phoneNumber: fields[2] as String,
      isPrimary: fields[3] as bool,
      isVerified: fields[4] as bool,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, PhoneModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.isPrimary)
      ..writeByte(4)
      ..write(obj.isVerified)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhoneModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PhoneModel _$PhoneModelFromJson(Map<String, dynamic> json) => PhoneModel(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      phoneNumber: json['phone_number'] as String,
      isPrimary: json['is_primary'] as bool,
      isVerified: json['is_verified'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$PhoneModelToJson(PhoneModel instance) {
  final val = <String, dynamic>{};

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('id', instance.id);
  val['user_id'] = instance.userId;
  val['phone_number'] = instance.phoneNumber;
  val['is_primary'] = instance.isPrimary;
  val['is_verified'] = instance.isVerified;
  val['created_at'] = instance.createdAt.toIso8601String();
  return val;
}
