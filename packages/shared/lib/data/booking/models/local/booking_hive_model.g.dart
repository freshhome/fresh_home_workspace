// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'booking_hive_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BookingHiveModelAdapter extends TypeAdapter<BookingHiveModel> {
  @override
  final int typeId = 17;

  @override
  BookingHiveModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BookingHiveModel(
      id: fields[0] as String,
      userId: fields[1] as String,
      service: fields[2] as BookedServiceHiveModel,
      address: fields[3] as AddressModel,
      scheduledAt: fields[4] as DateTime,
      startTimeSlot: fields[14] as String,
      price: fields[5] as BookingPricingHiveModel,
      status: fields[6] as OrderStatus,
      contact: fields[7] as ContactHiveModel,
      createdAt: fields[8] as DateTime,
      updatedAt: fields[9] as DateTime,
      addressId: fields[10] as String?,
      serviceId: fields[11] as String?,
      readableId: fields[12] as String?,
      technicianId: fields[13] as String?,
      assignedAt: fields[15] as DateTime?,
      acceptedAt: fields[16] as DateTime?,
      dispatchedAt: fields[17] as DateTime?,
      arrivedAt: fields[18] as DateTime?,
      startedAt: fields[19] as DateTime?,
      completedAt: fields[20] as DateTime?,
      cancelledAt: fields[21] as DateTime?,
      cancellationReasonCode: fields[22] as String?,
      cancelledByRole: fields[23] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, BookingHiveModel obj) {
    writer
      ..writeByte(24)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.service)
      ..writeByte(3)
      ..write(obj.address)
      ..writeByte(4)
      ..write(obj.scheduledAt)
      ..writeByte(5)
      ..write(obj.price)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.contact)
      ..writeByte(8)
      ..write(obj.createdAt)
      ..writeByte(9)
      ..write(obj.updatedAt)
      ..writeByte(10)
      ..write(obj.addressId)
      ..writeByte(11)
      ..write(obj.serviceId)
      ..writeByte(12)
      ..write(obj.readableId)
      ..writeByte(13)
      ..write(obj.technicianId)
      ..writeByte(14)
      ..write(obj.startTimeSlot)
      ..writeByte(15)
      ..write(obj.assignedAt)
      ..writeByte(16)
      ..write(obj.acceptedAt)
      ..writeByte(17)
      ..write(obj.dispatchedAt)
      ..writeByte(18)
      ..write(obj.arrivedAt)
      ..writeByte(19)
      ..write(obj.startedAt)
      ..writeByte(20)
      ..write(obj.completedAt)
      ..writeByte(21)
      ..write(obj.cancelledAt)
      ..writeByte(22)
      ..write(obj.cancellationReasonCode)
      ..writeByte(23)
      ..write(obj.cancelledByRole);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BookingHiveModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
