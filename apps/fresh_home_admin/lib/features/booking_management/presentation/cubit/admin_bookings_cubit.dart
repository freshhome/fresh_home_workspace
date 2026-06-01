import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/booking/entities/booking/booking.dart';
import '../../domain/usecases/admin_watch_bookings.dart';

abstract class AdminBookingsState {}

class AdminBookingsInitial extends AdminBookingsState {}

class AdminBookingsLoading extends AdminBookingsState {}

class AdminBookingsLoaded extends AdminBookingsState {
  final List<Booking> activeBookings;
  final List<Booking> completedBookings;
  final List<Booking> cancelledBookings;
  final List<Booking> allBookings;

  AdminBookingsLoaded({
    this.activeBookings = const [],
    this.completedBookings = const [],
    this.cancelledBookings = const [],
    this.allBookings = const [],
  });

  AdminBookingsLoaded copyWith({
    List<Booking>? activeBookings,
    List<Booking>? completedBookings,
    List<Booking>? cancelledBookings,
    List<Booking>? allBookings,
  }) {
    return AdminBookingsLoaded(
      activeBookings: activeBookings ?? this.activeBookings,
      completedBookings: completedBookings ?? this.completedBookings,
      cancelledBookings: cancelledBookings ?? this.cancelledBookings,
      allBookings: allBookings ?? this.allBookings,
    );
  }
}

class AdminBookingsError extends AdminBookingsState {
  final String message;
  AdminBookingsError(this.message);
}

class AdminBookingsCubit extends Cubit<AdminBookingsState> {
  final AdminWatchBookings _watchBookings;
  final List<StreamSubscription> _subscriptions = [];

  AdminBookingsCubit(this._watchBookings) : super(AdminBookingsInitial()) {
    _initStreams();
    refreshBookings(); // Test one-time fetch
  }

  Future<void> refreshBookings() async {
    debugPrint('🚀 [AdminBookingsCubit] Manual Refresh Triggered...');
    final result = await _watchBookings.getAll();
    result.fold(
      (l) => debugPrint('❌ [AdminBookingsCubit] Refresh Error: ${l.message}'),
      (r) {
        debugPrint('✅ [AdminBookingsCubit] Refresh Success: ${r.length} bookings found');
        // We don't necessarily need to emit here if the stream is working, 
        // but it helps verify data existence.
        if (state is! AdminBookingsLoaded) {
           // If stream hasn't emitted yet, we can use this data
           emit(AdminBookingsLoaded(allBookings: r));
        }
      },
    );
  }

  void _initStreams() {
    emit(AdminBookingsLoading());

    // 1. Watch Active
    _subscriptions.add(_watchBookings.watchActive().listen((result) {
      debugPrint('🚀 [AdminBookingsCubit] Active Bookings Result: $result');
      result.fold(
        (l) => emit(AdminBookingsError(l.message)),
        (r) {
          debugPrint('✅ [AdminBookingsCubit] Active Bookings Count: ${r.length}');
          if (state is AdminBookingsLoaded) {
            emit((state as AdminBookingsLoaded).copyWith(activeBookings: r));
          } else {
            emit(AdminBookingsLoaded(activeBookings: r));
          }
        },
      );
    }));

    // 2. Watch Completed
    _subscriptions.add(_watchBookings.watchCompleted().listen((result) {
      debugPrint('🚀 [AdminBookingsCubit] Completed Bookings Result: $result');
      result.fold(
        (l) => emit(AdminBookingsError(l.message)),
        (r) {
          debugPrint('✅ [AdminBookingsCubit] Completed Bookings Count: ${r.length}');
          if (state is AdminBookingsLoaded) {
            emit((state as AdminBookingsLoaded).copyWith(completedBookings: r));
          } else {
            emit(AdminBookingsLoaded(completedBookings: r));
          }
        },
      );
    }));

    // 3. Watch Cancelled
    _subscriptions.add(_watchBookings.watchCancelled().listen((result) {
      debugPrint('🚀 [AdminBookingsCubit] Cancelled Bookings Result: $result');
      result.fold(
        (l) => emit(AdminBookingsError(l.message)),
        (r) {
          debugPrint('✅ [AdminBookingsCubit] Cancelled Bookings Count: ${r.length}');
          if (state is AdminBookingsLoaded) {
            emit((state as AdminBookingsLoaded).copyWith(cancelledBookings: r));
          } else {
            emit(AdminBookingsLoaded(cancelledBookings: r));
          }
        },
      );
    }));

    // 4. Watch All
    _subscriptions.add(_watchBookings.watchAll().listen((result) {
      debugPrint('🚀 [AdminBookingsCubit] All Bookings Result: $result');
      result.fold(
        (l) => emit(AdminBookingsError(l.message)),
        (r) {
          debugPrint('✅ [AdminBookingsCubit] All Bookings Count: ${r.length}');
          if (state is AdminBookingsLoaded) {
            emit((state as AdminBookingsLoaded).copyWith(allBookings: r));
          } else {
            emit(AdminBookingsLoaded(allBookings: r));
          }
        },
      );
    }));
  }

  @override
  Future<void> close() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    return super.close();
  }
}
