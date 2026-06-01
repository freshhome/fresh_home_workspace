import 'package:shared/domain/booking/entities/booking/booking.dart';

abstract class MyOrdersState {}

class MyOrdersInitial extends MyOrdersState {}

class MyOrdersLoading extends MyOrdersState {}

class MyOrdersLoaded extends MyOrdersState {
  final List<Booking> upcomingOrders;
  final List<Booking> todayOrders;
  final List<Booking> historyOrders;
  final int selectedTabIndex;
  final bool isUpdating;

  MyOrdersLoaded({
    required this.upcomingOrders,
    required this.todayOrders,
    required this.historyOrders,
    this.selectedTabIndex = 0,
    this.isUpdating = false,
  });

  MyOrdersLoaded copyWith({
    List<Booking>? upcomingOrders,
    List<Booking>? todayOrders,
    List<Booking>? historyOrders,
    int? selectedTabIndex,
    bool? isUpdating,
  }) {
    return MyOrdersLoaded(
      upcomingOrders: upcomingOrders ?? this.upcomingOrders,
      todayOrders: todayOrders ?? this.todayOrders,
      historyOrders: historyOrders ?? this.historyOrders,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isUpdating: isUpdating ?? this.isUpdating,
    );
  }
}

class MyOrdersError extends MyOrdersState {
  final String message;
  MyOrdersError(this.message);
}
