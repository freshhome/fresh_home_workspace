// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pricing_method.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PricingMethodAdapter extends TypeAdapter<PricingMethod> {
  @override
  final int typeId = 12;

  @override
  PricingMethod read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return PricingMethod.perSquareMeter;
      case 1:
        return PricingMethod.perLinearMeter;
      case 2:
        return PricingMethod.fixed;
      case 3:
        return PricingMethod.perIssue;
      case 4:
        return PricingMethod.unknown;
      case 5:
        return PricingMethod.inspection;
      default:
        return PricingMethod.perSquareMeter;
    }
  }

  @override
  void write(BinaryWriter writer, PricingMethod obj) {
    switch (obj) {
      case PricingMethod.perSquareMeter:
        writer.writeByte(0);
        break;
      case PricingMethod.perLinearMeter:
        writer.writeByte(1);
        break;
      case PricingMethod.fixed:
        writer.writeByte(2);
        break;
      case PricingMethod.perIssue:
        writer.writeByte(3);
        break;
      case PricingMethod.unknown:
        writer.writeByte(4);
        break;
      case PricingMethod.inspection:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingMethodAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

const _$PricingMethodEnumMap = {
  PricingMethod.perSquareMeter: 'per_square_meter',
  PricingMethod.perLinearMeter: 'per_linear_meter',
  PricingMethod.fixed: 'fixed',
  PricingMethod.perIssue: 'per_issue',
  PricingMethod.unknown: 'unknown',
  PricingMethod.inspection: 'inspection',
};
