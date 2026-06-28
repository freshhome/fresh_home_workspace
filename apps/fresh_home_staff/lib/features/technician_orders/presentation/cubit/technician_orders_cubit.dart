import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shared/shared.dart';
import 'package:shared_features/shared_features.dart';
import '../../../finance/presentation/cubit/technician_finance_cubit.dart';
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

            // 1. Cancelled orders: status is cancelled (any date)
            final List<Booking> cancelled = orders
                .where((o) => o.status == OrderStatus.cancelled)
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(b).compareTo(_getDateTime(a)));

            // 2. History orders: status is completed OR scheduled date is before today start AND status is not cancelled
            final List<Booking> history = orders
                .where((o) =>
                    o.status == OrderStatus.completed ||
                    (_getDateTime(o).isBefore(todayStart) && o.status != OrderStatus.cancelled))
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(b).compareTo(_getDateTime(a)));

            // 3. Today orders: scheduled date is today AND status is not completed and not cancelled
            final List<Booking> today = orders
                .where((o) =>
                    !_getDateTime(o).isBefore(todayStart) &&
                    _getDateTime(o).isBefore(todayEnd) &&
                    o.status != OrderStatus.completed &&
                    o.status != OrderStatus.cancelled)
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(a).compareTo(_getDateTime(b)));

            // 4. Upcoming orders: scheduled date is after today AND status is not completed and not cancelled
            final List<Booking> upcoming = orders
                .where((o) =>
                    !_getDateTime(o).isBefore(todayEnd) &&
                    o.status != OrderStatus.completed &&
                    o.status != OrderStatus.cancelled)
                .toList()
              ..sort((Booking a, Booking b) =>
                  _getDateTime(a).compareTo(_getDateTime(b)));

            final upcomingGroups = _groupOrdersByDate(upcoming);
            final historyGroups = _groupOrdersByDate(history);
            final cancelledGroups = _groupOrdersByDate(cancelled);

            final currentTabIndex = state is TechnicianOrdersLoaded
                ? (state as TechnicianOrdersLoaded).selectedTabIndex
                : 0;

            emit(TechnicianOrdersLoaded(
              upcomingGroups: upcomingGroups,
              todayOrders: today,
              historyGroups: historyGroups,
              cancelledGroups: cancelledGroups,
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
    Map<String, dynamic>? metadata,
  }) async {
    final currentState = state;
    if (currentState is! TechnicianOrdersLoaded) return;

    debugPrint('🔵 [TechnicianOrdersCubit] Transition Start: ${booking.displayId} -> ${newStatus.name}');
    emit(currentState.copyWith(
      isTransitioning: true, 
      clearError: true,
    ));

    final Map<String, dynamic> actualMetadata = Map<String, dynamic>.from(metadata ?? {});
    if (newStatus == OrderStatus.inProgress) {
      actualMetadata['otp'] = 'bypass';
    }

    final result = await transitionBooking(TransitionBookingParams(
      bookingId: booking.id,
      newStatus: newStatus,
      actorId: technicianId,
      actorRole: actorRole ?? 'technician',
      reason: reason,
      notes: notes,
      metadata: actualMetadata,
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
        final List<DailyOrderGroup> updatedCancelled = currentState.cancelledGroups.map((g) {
           return DailyOrderGroup(
             date: g.date,
             orders: g.orders.map((o) => o.id == booking.id ? updatedOrder : o).toList(),
           );
        }).toList();

        emit(currentState.copyWith(
          todayOrders: updatedToday,
          upcomingGroups: updatedUpcoming,
          historyGroups: updatedHistory,
          cancelledGroups: updatedCancelled,
          isTransitioning: false,
          clearError: true,
        ));

        // Auto-refresh profile and finance data when order is completed or cancelled
        if (newStatus == OrderStatus.completed || newStatus == OrderStatus.cancelled) {
          GetIt.instance<ProfileCubit>().load();
          GetIt.instance<TechnicianFinanceCubit>().loadFinancialData();
        }
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
        debugPrint('✅ [TechnicianOrdersCubit] Update Booking Success. Handling transition...');
        
        final currentStatus = booking.status;
        if (currentStatus == OrderStatus.arrived) {
          debugPrint('🔵 [TechnicianOrdersCubit] Booking is arrived. Transitioning to pending_inspection first...');
          final transitionPendingResult = await transitionBooking(TransitionBookingParams(
            bookingId: booking.id,
            newStatus: OrderStatus.pendingInspection,
            actorId: technicianId,
            actorRole: 'technician',
            notes: 'Technician starting inspection quote submission',
          ));

          await transitionPendingResult.fold(
            (failure) async {
              debugPrint('❌ [TechnicianOrdersCubit] Transition to pendingInspection Failed: ${failure.message}');
              emit(currentState.copyWith(
                isTransitioning: false,
                transitionError: failure.message,
              ));
            },
            (_) async {
              debugPrint('✅ [TechnicianOrdersCubit] Transition to pendingInspection Success. Now transitioning to in_progress...');
              await _transitionToInProgress(currentState, updatedBooking, technicianId);
            },
          );
        } else {
          debugPrint('🔵 [TechnicianOrdersCubit] Booking is already in pending_inspection. Transitioning directly to in_progress...');
          await _transitionToInProgress(currentState, updatedBooking, technicianId);
        }
      },
    );
  }

  Future<void> _transitionToInProgress(
    TechnicianOrdersLoaded currentState,
    Booking updatedBooking,
    String technicianId,
  ) async {
    final transitionResult = await transitionBooking(TransitionBookingParams(
      bookingId: updatedBooking.id,
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

        final List<Booking> updatedToday = currentState.todayOrders.map((o) => o.id == updatedBooking.id ? finalOrder : o).toList();
        final List<DailyOrderGroup> updatedUpcoming = currentState.upcomingGroups.map((g) {
           return DailyOrderGroup(
             date: g.date,
             orders: g.orders.map((o) => o.id == updatedBooking.id ? finalOrder : o).toList(),
           );
        }).toList();
        final List<DailyOrderGroup> updatedHistory = currentState.historyGroups.map((g) {
           return DailyOrderGroup(
             date: g.date,
             orders: g.orders.map((o) => o.id == updatedBooking.id ? finalOrder : o).toList(),
           );
        }).toList();
        final List<DailyOrderGroup> updatedCancelled = currentState.cancelledGroups.map((g) {
           return DailyOrderGroup(
             date: g.date,
             orders: g.orders.map((o) => o.id == updatedBooking.id ? finalOrder : o).toList(),
           );
        }).toList();

        emit(currentState.copyWith(
          todayOrders: updatedToday,
          upcomingGroups: updatedUpcoming,
          historyGroups: updatedHistory,
          cancelledGroups: updatedCancelled,
          isTransitioning: false,
          clearError: true,
        ));
      },
    );
  }

  Future<void> completeOrderWithCash({
    required Booking booking,
    required String technicianId,
    required double collectedAmount,
  }) async {
    final currentState = state;
    if (currentState is! TechnicianOrdersLoaded) return;

    emit(currentState.copyWith(
      isTransitioning: true,
      clearError: true,
    ));

    // Update pricingInputs with payment method and collected amount
    final updatedBooking = booking.copyWith(
      pricingInputs: {
        ...?booking.pricingInputs,
        'payment_method': 'cash',
        'collected_amount': collectedAmount,
      },
    );

    final updateResult = await updateBooking(booking: updatedBooking);

    await updateResult.fold(
      (failure) async {
        debugPrint('❌ [TechnicianOrdersCubit] Complete Cash Update Failed: ${failure.message}');
        emit(currentState.copyWith(
          isTransitioning: false,
          transitionError: failure.message,
        ));
      },
      (_) async {
        debugPrint('✅ [TechnicianOrdersCubit] Complete Cash Update Success. Transitioning to completed...');
        final result = await transitionBooking(TransitionBookingParams(
          bookingId: booking.id,
          newStatus: OrderStatus.completed,
          actorId: technicianId,
          actorRole: 'technician',
          notes: 'Completed order with cash collection of $collectedAmount',
        ));

        result.fold(
          (failure) {
            debugPrint('❌ [TechnicianOrdersCubit] Complete Cash Transition Failed: ${failure.message}');
            emit(currentState.copyWith(
              isTransitioning: false,
              transitionError: failure.message,
            ));
          },
          (_) {
            debugPrint('✅ [TechnicianOrdersCubit] Complete Cash Transition Success.');
            
            final now = DateTime.now();
            final fullyUpdated = updatedBooking.copyWith(
              status: OrderStatus.completed,
              completedAt: now,
            );

            final List<Booking> updatedToday = currentState.todayOrders.map((o) => o.id == booking.id ? fullyUpdated : o).toList();
            final List<DailyOrderGroup> updatedUpcoming = currentState.upcomingGroups.map((g) {
               return DailyOrderGroup(
                 date: g.date,
                 orders: g.orders.map((o) => o.id == booking.id ? fullyUpdated : o).toList(),
               );
            }).toList();
            final List<DailyOrderGroup> updatedHistory = currentState.historyGroups.map((g) {
               return DailyOrderGroup(
                 date: g.date,
                 orders: g.orders.map((o) => o.id == booking.id ? fullyUpdated : o).toList(),
               );
            }).toList();
            final List<DailyOrderGroup> updatedCancelled = currentState.cancelledGroups.map((g) {
               return DailyOrderGroup(
                 date: g.date,
                 orders: g.orders.map((o) => o.id == booking.id ? fullyUpdated : o).toList(),
               );
            }).toList();

            emit(currentState.copyWith(
              todayOrders: updatedToday,
              upcomingGroups: updatedUpcoming,
              historyGroups: updatedHistory,
              cancelledGroups: updatedCancelled,
              isTransitioning: false,
              clearError: true,
            ));

            // Auto-refresh profile and finance data on cash collection completion
            GetIt.instance<ProfileCubit>().load();
            GetIt.instance<TechnicianFinanceCubit>().loadFinancialData();
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
