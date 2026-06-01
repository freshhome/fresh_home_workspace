import 'package:hive/hive.dart';
import 'package:shared/core/constants/hive_constants.dart';
import 'package:shared/domain/booking/entities/booking/sub_entities/booking_components.dart';

/// Professional Hive adapter for OrderStatus.
/// Stores status as a string to ensure data integrity across enum changes.
class OrderStatusAdapter extends TypeAdapter<OrderStatus> {
  @override
  final int typeId = HiveTypeIds.orderStatus;

  @override
  OrderStatus read(BinaryReader reader) {
    final statusName = reader.readString();
    return OrderStatus.values.firstWhere(
      (e) => e.name == statusName,
      orElse: () => OrderStatus.created,
    );
  }

  @override
  void write(BinaryWriter writer, OrderStatus obj) {
    writer.writeString(obj.name);
  }
}
