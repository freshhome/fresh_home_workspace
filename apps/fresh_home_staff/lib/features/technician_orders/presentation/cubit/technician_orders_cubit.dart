import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/shared.dart';
import '../../domain/use_cases/get_all_orders.dart';
import '../../domain/entities/daily_order_group.dart';
import 'technician_orders_state.dart';

class TechnicianOrdersCubit extends Cubit<TechnicianOrdersState> {
  final GetAllOrders getAllOrders;
  final TransitionBookingUseCase transitionBooking;
  final UpdateBookingUseCase updateBooking;
  final CalculatePriceUseCase calculatePrice;
  StreamSubscription? _ordersSubscription;

  TechnicianOrdersCubit({
    required this.getAllOrders,
    required this.transitionBooking,
    required this.updateBooking,
    required this.calculatePrice,
  }) : super(TechnicianOrdersInitial());

  Future<void> loadOrders({List<String>? serviceNames}) async {
    emit(TechnicianOrdersLoading());

    await _ordersSubscription?.cancel();
    _ordersSubscription = getAllOrders(serviceNames: serviceNames).listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) {
            debugPrint('❌ [TechnicianOrdersCubit] Load Orders Failed: ${failure.message}');
            emit(TechnicianOrdersError(failure.message));
          },
          (List<Booking> orders) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final todayEnd = todayStart.add(const Duration(days: 1));

            final List<Booking> upcoming = orders
                .where((o) => !_getDateTime(o).isBefore(todayEnd))
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(a).compareTo(_getDateTime(b)));

            final List<Booking> today = orders
                .where((o) =>
                    !_getDateTime(o).isBefore(todayStart) &&
                    _getDateTime(o).isBefore(todayEnd))
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(a).compareTo(_getDateTime(b)));

            final List<Booking> history = orders
                .where((o) => _getDateTime(o).isBefore(todayStart))
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(b).compareTo(_getDateTime(a)));

            final upcomingGroups = _groupOrdersByDate(upcoming);
            final historyGroups = _groupOrdersByDate(history);

            final currentTabIndex = state is TechnicianOrdersLoaded
                ? (state as TechnicianOrdersLoaded).selectedTabIndex
                : 0;

            emit(TechnicianOrdersLoaded(
              upcomingGroups: upcomingGroups,
              todayOrders: today,
              historyGroups: historyGroups,
              selectedTabIndex: currentTabIndex,
            ));
          },
        );
      },
      onError: (e) => emit(TechnicianOrdersError(e.toString())),
    );
  }

  Future<void> transitionOrder({
    required Booking booking,
    required OrderStatus newStatus,
    required String technicianId, // This is our actorId here
    String? actorRole = 'technician',
    String? reason,
    String? notes,
  }) async {
    final currentState = state;
    if (currentState is! TechnicianOrdersLoaded) return;

    debugPrint('🔵 [TechnicianOrdersCubit] Transition Start: ${booking.displayId} -> ${newStatus.name}');
    emit(currentState.copyWith(
      isTransitioning: true, 
      clearError: true,
    ));

    final result = await transitionBooking(TransitionBookingParams(
      bookingId: booking.id,
      newStatus: newStatus,
      actorId: technicianId,
      actorRole: actorRole ?? 'technician',
      reason: reason,
      notes: notes,
    ));

    result.fold(
      (failure) {
        debugPrint('❌ [TechnicianOrdersCubit] Transition Failed: ${failure.message}');
        emit(currentState.copyWith(
          isTransitioning: false,
          transitionError: failure.message,
        ));
      },
      (_) {
        debugPrint('✅ [TechnicianOrdersCubit] Transition Success: ${booking.displayId} -> ${newStatus.name}');
        
        // Optimistic/Immediate update with precise timestamp
        final now = DateTime.now();
        final updatedOrder = booking.copyWith(
          status: newStatus,
          acceptedAt: newStatus == OrderStatus.accepted ? now : booking.acceptedAt,
          dispatchedAt: newStatus == OrderStatus.onTheWay ? now : booking.dispatchedAt,
          arrivedAt: newStatus == OrderStatus.arrived ? now : booking.arrivedAt,
          startedAt: newStatus == OrderStatus.inProgress ? now : booking.startedAt,
          completedAt: newStatus == OrderStatus.completed ? now : booking.completedAt,
          cancelledAt: newStatus == OrderStatus.cancelled ? now : booking.cancelledAt,
        );

        final List<Booking> updatedToday = currentState.todayOrders.map((o) => o.id == booking.id ? updatedOrder : o).toList();
        final List<DailyOrderGroup> updatedUpcoming = currentState.upcomingGroups.map((g) {
           return DailyOrderGroup(
             date: g.date,
             orders: g.orders.map((o) => o.id == booking.id ? updatedOrder : o).toList(),
           );
        }).toList();
        final List<DailyOrderGroup> updatedHistory = currentState.historyGroups.map((g) {
           return DailyOrderGroup(
             date: g.date,
             orders: g.orders.map((o) => o.id == booking.id ? updatedOrder : o).toList(),
           );
        }).toList();

        emit(currentState.copyWith(
          todayOrders: updatedToday,
          upcomingGroups: updatedUpcoming,
          historyGroups: updatedHistory,
          isTransitioning: false,
          clearError: true,
        ));
      },
    );
  }

  DateTime _getDateTime(Booking booking) {
    return booking.scheduledAt;
  }

  List<DailyOrderGroup> _groupOrdersByDate(List<Booking> orders) {
    if (orders.isEmpty) return [];

    final groups = <DailyOrderGroup>[];
    final Map<String, List<Booking>> groupedMap = {};

    for (var order in orders) {
      final dt = _getDateTime(order);
      final dateKey = "${dt.year}-${dt.month}-${dt.day}";
      if (!groupedMap.containsKey(dateKey)) {
        groupedMap[dateKey] = [];
      }
      groupedMap[dateKey]!.add(order);
    }

    groupedMap.forEach((key, groupOrders) {
      if (groupOrders.isNotEmpty) {
        groups.add(DailyOrderGroup(
            date: _getDateTime(groupOrders.first), orders: groupOrders));
      }
    });

    return groups;
  }

  Future<void> submitPostInspectionQuote({
    required Booking booking,
    required Map<String, dynamic> dynamicInputs,
    required BookingPricing pricing,
    required String technicianId,
  }) async {
    final currentState = state;
    if (currentState is! TechnicianOrdersLoaded) return;

    emit(currentState.copyWith(
      isTransitioning: true,
      clearError: true,
    ));

    final updatedBooking = booking.copyWith(
      pricingInputs: dynamicInputs,
      price: pricing,
    );

    final updateResult = await updateBooking(booking: updatedBooking);

    updateResult.fold(
      (failure) {
        debugPrint('❌ [TechnicianOrdersCubit] Update Booking Failed: ${failure.message}');
        emit(currentState.copyWith(
          isTransitioning: false,
          transitionError: failure.message,
        ));
      },
      (_) async {
        debugPrint('✅ [TechnicianOrdersCubit] Update Booking Success. Transitioning to in_progress...');
        
        final transitionResult = await transitionBooking(TransitionBookingParams(
          bookingId: booking.id,
          newStatus: OrderStatus.inProgress,
          actorId: technicianId,
          actorRole: 'technician',
          notes: 'Technician completed inspection and started job',
        ));

        transitionResult.fold(
          (failure) {
            debugPrint('❌ [TechnicianOrdersCubit] Transition to inProgress Failed: ${failure.message}');
            emit(currentState.copyWith(
              isTransitioning: false,
              transitionError: failure.message,
            ));
          },
          (_) {
            debugPrint('✅ [TechnicianOrdersCubit] Transition to inProgress Success.');
            
            final now = DateTime.now();
            final finalOrder = updatedBooking.copyWith(
              status: OrderStatus.inProgress,
              startedAt: now,
            );

            final List<Booking> updatedToday = currentState.todayOrders.map((o) => o.id == booking.id ? finalOrder : o).toList();
            final List<DailyOrderGroup> updatedUpcoming = currentState.upcomingGroups.map((g) {
               return DailyOrderGroup(
                 date: g.date,
                 orders: g.orders.map((o) => o.id == booking.id ? finalOrder : o).toList(),
               );
            }).toList();
            final List<DailyOrderGroup> updatedHistory = currentState.historyGroups.map((g) {
               return DailyOrderGroup(
                 date: g.date,
                 orders: g.orders.map((o) => o.id == booking.id ? finalOrder : o).toList(),
               );
            }).toList();

            emit(currentState.copyWith(
              todayOrders: updatedToday,
              upcomingGroups: updatedUpcoming,
              historyGroups: updatedHistory,
              isTransitioning: false,
              clearError: true,
            ));
          },
        );
      },
    );
  }

  void changeTab(int index) {
    if (state is TechnicianOrdersLoaded) {
      emit((state as TechnicianOrdersLoaded).copyWith(selectedTabIndex: index));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
