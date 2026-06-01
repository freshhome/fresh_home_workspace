import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_features/shared_features.dart';

import '../../domain/use_cases/get_my_orders.dart';
import 'my_orders_state.dart';

class MyOrdersCubit extends Cubit<MyOrdersState> {
  final GetMyOrders getMyOrders;
  final AuthLocalDataSource localDataSource;
  StreamSubscription? _ordersSubscription;

  MyOrdersCubit({
    required this.getMyOrders,
    required this.localDataSource,
  }) : super(MyOrdersInitial());

  Future<void> loadOrders() async {
    final user = localDataSource.getCachedUser();
    if (user == null) {
      emit(MyOrdersError("المستخدم غير مسجل"));
      return;
    }

    emit(MyOrdersLoading());

    await _ordersSubscription?.cancel();
    _ordersSubscription = getMyOrders(user.uid).listen(
      (result) {
        if (isClosed) return;
        result.fold(
          (failure) => emit(MyOrdersError(failure.message)),
          (orders) {
            final now = DateTime.now();
            final todayStart = DateTime(now.year, now.month, now.day);
            final todayEnd = todayStart.add(const Duration(days: 1));

            final upcoming = orders.where((o) => !o.scheduledAt.isBefore(todayEnd)).toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            final today = orders.where((o) => !o.scheduledAt.isBefore(todayStart) && o.scheduledAt.isBefore(todayEnd)).toList()
              ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

            final history = orders.where((o) => o.scheduledAt.isBefore(todayStart)).toList()
              ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

            final currentTabIndex = state is MyOrdersLoaded ? (state as MyOrdersLoaded).selectedTabIndex : 0;
            final currentIsUpdating = state is MyOrdersLoaded ? (state as MyOrdersLoaded).isUpdating : false;

            emit(MyOrdersLoaded(
              upcomingOrders: upcoming,
              todayOrders: today,
              historyOrders: history,
              selectedTabIndex: currentTabIndex,
              isUpdating: currentIsUpdating,
            ));
          },
        );
      },
      onError: (e) => emit(MyOrdersError(e.toString())),
    );
  }

  Future<void> cancelOrder(String orderId) async {
    if (state is MyOrdersLoaded) {
      emit((state as MyOrdersLoaded).copyWith(isUpdating: true));
    }

    final result = await getMyOrders.repository.cancelBooking(bookingId: orderId);

    // إضافة تأخير اصطناعي لضمان رؤية مؤشر التحميل
    await Future.delayed(const Duration(seconds: 2));

    if (isClosed) return;

    result.fold(
      (failure) {
        if (state is MyOrdersLoaded) {
          emit((state as MyOrdersLoaded).copyWith(isUpdating: false));
        }
        emit(MyOrdersError(failure.message));
      },
      (_) {
        if (state is MyOrdersLoaded) {
          emit((state as MyOrdersLoaded).copyWith(isUpdating: false));
        }
      },
    );
  }

  void changeTab(int index) {
    if (state is MyOrdersLoaded) {
      emit((state as MyOrdersLoaded).copyWith(selectedTabIndex: index));
    }
  }

  @override
  Future<void> close() {
    _ordersSubscription?.cancel();
    return super.close();
  }
}
