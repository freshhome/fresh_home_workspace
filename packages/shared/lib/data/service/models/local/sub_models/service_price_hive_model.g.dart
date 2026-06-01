// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_price_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PriceOptionHiveModelAdapter extends TypeAdapter<PriceOptionHiveModel> {
  @override
  final int typeId = 10;

  @override
  PriceOptionHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceOptionHiveModel(
      key: fields[0] as String?,
      value: fields[1] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceOptionHiveModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.key)
      ..writeByte(1)
      ..write(obj.value);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceOptionHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriceHiveModelAdapter extends TypeAdapter<PriceHiveModel> {
  @override
  final int typeId = 9;

  @override
  PriceHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PriceHiveModel(
      type: fields[0] as PricingMethod,
      value: fields[1] as double,
      unit: fields[2] as String,
      options: (fields[3] as List).cast<PriceOptionHiveModel>(),
      fields: (fields[4] as List?)?.cast<dynamic>(),
      basePriceFormula: fields[5] as String?,
      minPrice: fields[6] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, PriceHiveModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.type)
      ..writeByte(1)
      ..write(obj.value)
      ..writeByte(2)
      ..write(obj.unit)
      ..writeByte(3)
      ..write(obj.options)
      ..writeByte(4)
      ..write(obj.fields)
      ..writeByte(5)
      ..write(obj.basePriceFormula)
      ..writeByte(6)
      ..write(obj.minPrice);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriceHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
