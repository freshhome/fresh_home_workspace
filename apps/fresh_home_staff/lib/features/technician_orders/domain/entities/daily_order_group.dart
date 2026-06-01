import 'package:shared/domain/booking/entities/booking/booking.dart';

class DailyOrderGroup {
  final DateTime date;
  final List<Booking> orders;

  DailyOrderGroup({
    required this.date,
    required this.orders,
  });

  double get totalAmount => orders.fold(0, (sum, order) => sum + order.price.total);
  int get orderCount => orders.length;
}
