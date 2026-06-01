// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_status.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ServiceStatusAdapter extends TypeAdapter<ServiceStatus> {
  @override
  final int typeId = 13;

  @override
  ServiceStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ServiceStatus.draft;
      case 1:
        return ServiceStatus.review;
      case 2:
        return ServiceStatus.ready;
      case 3:
        return ServiceStatus.active;
      case 4:
        return ServiceStatus.paused;
      case 5:
        return ServiceStatus.archived;
      default:
        return ServiceStatus.draft;
    }
  }

  @override
  void write(BinaryWriter writer, ServiceStatus obj) {
    switch (obj) {
      case ServiceStatus.draft:
        writer.writeByte(0);
        break;
      case ServiceStatus.review:
        writer.writeByte(1);
        break;
      case ServiceStatus.ready:
        writer.writeByte(2);
        break;
      case ServiceStatus.active:
        writer.writeByte(3);
        break;
      case ServiceStatus.paused:
        writer.writeByte(4);
        break;
      case ServiceStatus.archived:
        writer.writeByte(5);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ServiceStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
