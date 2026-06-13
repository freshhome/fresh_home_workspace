import 'package:shared/domain/booking/entities/booking/booking.dart';
import '../../domain/entities/daily_order_group.dart';

abstract class TechnicianOrdersState {}

class TechnicianOrdersInitial extends TechnicianOrdersState {}

class TechnicianOrdersLoading extends TechnicianOrdersState {}

class TechnicianOrdersLoaded extends TechnicianOrdersState {
  final List<DailyOrderGroup> upcomingGroups;
  final List<Booking> todayOrders;
  final List<DailyOrderGroup> historyGroups;
  final List<DailyOrderGroup> cancelledGroups;
  final int selectedTabIndex;
  final bool isTransitioning;
  final String? transitionError;

  TechnicianOrdersLoaded({
    required this.upcomingGroups,
    required this.todayOrders,
    required this.historyGroups,
    required this.cancelledGroups,
    this.selectedTabIndex = 0,
    this.isTransitioning = false,
    this.transitionError,
  });

  TechnicianOrdersLoaded copyWith({
    List<DailyOrderGroup>? upcomingGroups,
    List<Booking>? todayOrders,
    List<DailyOrderGroup>? historyGroups,
    List<DailyOrderGroup>? cancelledGroups,
    int? selectedTabIndex,
    bool? isTransitioning,
    String? transitionError,
    bool clearError = false,
  }) {
    return TechnicianOrdersLoaded(
      upcomingGroups: upcomingGroups ?? this.upcomingGroups,
      todayOrders: todayOrders ?? this.todayOrders,
      historyGroups: historyGroups ?? this.historyGroups,
      cancelledGroups: cancelledGroups ?? this.cancelledGroups,
      selectedTabIndex: selectedTabIndex ?? this.selectedTabIndex,
      isTransitioning: isTransitioning ?? this.isTransitioning,
      transitionError: clearError ? null : (transitionError ?? this.transitionError),
    );
  }
}

class TechnicianOrdersError extends TechnicianOrdersState {
  final String message;
  TechnicianOrdersError(this.message);
}
