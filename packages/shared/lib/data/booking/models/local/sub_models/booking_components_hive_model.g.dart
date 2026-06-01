// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_components_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookedServiceHiveModelAdapter
    extends TypeAdapter<BookedServiceHiveModel> {
  @override
  final int typeId = 18;

  @override
  BookedServiceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookedServiceHiveModel(
      id: fields[0] as String,
      subServiceId: fields[1] as String,
      name: (fields[2] as Map).cast<String, String>(),
      image: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BookedServiceHiveModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.subServiceId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.image);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookedServiceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class BookingPricingHiveModelAdapter
    extends TypeAdapter<BookingPricingHiveModel> {
  @override
  final int typeId = 20;

  @override
  BookingPricingHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookingPricingHiveModel(
      basePrice: fields[0] as double,
      extraFees: fields[1] as double,
      discount: fields[2] as double,
      total: fields[3] as double,
      metadata: (fields[4] as Map?)?.cast<dynamic, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, BookingPricingHiveModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.basePrice)
      ..writeByte(1)
      ..write(obj.extraFees)
      ..writeByte(2)
      ..write(obj.discount)
      ..writeByte(3)
      ..write(obj.total)
      ..writeByte(4)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingPricingHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ContactHiveModelAdapter extends TypeAdapter<ContactHiveModel> {
  @override
  final int typeId = 19;

  @override
  ContactHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ContactHiveModel(
      name: fields[0] as String,
      phone: (fields[1] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, ContactHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.phone);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
