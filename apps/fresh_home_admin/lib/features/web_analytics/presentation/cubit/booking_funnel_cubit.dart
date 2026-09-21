import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_booking_funnel_stats_use_case.dart';
import 'booking_funnel_state.dart';

class BookingFunnelCubit extends Cubit<BookingFunnelState> {
  final GetBookingFunnelStatsUseCase getBookingFunnelStatsUseCase;

  FunnelDateFilter _activeFilter = FunnelDateFilter.all;
  DateTime? _activeStartDate;
  DateTime? _activeEndDate;
  DateTime? _customSelectedDate;
  String? _activeServiceId;

  BookingFunnelCubit({required this.getBookingFunnelStatsUseCase})
      : super(const BookingFunnelInitial());

  FunnelDateFilter get activeFilter => _activeFilter;
  DateTime? get customSelectedDate => _customSelectedDate;

  /// Changes date filter and reloads funnel statistics accordingly.
  Future<void> applyDateFilter(
    FunnelDateFilter filter, {
    DateTime? customDate,
  }) async {
    _activeFilter = filter;

    final now = DateTime.now();
    switch (filter) {
      case FunnelDateFilter.today:
        _activeStartDate = DateTime(now.year, now.month, now.day, 0, 0, 0);
        _activeEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case FunnelDateFilter.all:
        // Pass epoch or 2020 so backend RPC does not default to 30 days
        _activeStartDate = DateTime(2020, 1, 1).toUtc();
        _activeEndDate = DateTime.now().toUtc();
        break;
      case FunnelDateFilter.last7Days:
        _activeStartDate = DateTime(now.year, now.month, now.day - 6, 0, 0, 0);
        _activeEndDate = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);
        break;
      case FunnelDateFilter.custom:
        if (customDate != null) {
          _customSelectedDate = customDate;
          _activeStartDate =
              DateTime(customDate.year, customDate.month, customDate.day, 0, 0, 0);
          _activeEndDate =
              DateTime(customDate.year, customDate.month, customDate.day, 23, 59, 59, 999);
        }
        break;
    }

    await loadFunnelStats(
      startDate: _activeStartDate,
      endDate: _activeEndDate,
      serviceId: _activeServiceId,
      filter: _activeFilter,
      customDate: _customSelectedDate,
    );
  }

  Future<void> loadFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
    FunnelDateFilter? filter,
    DateTime? customDate,
  }) async {
    debugPrint('📊 [BookingFunnelCubit] Triggered loadFunnelStats()...');

    if (filter != null) _activeFilter = filter;
    if (customDate != null) _customSelectedDate = customDate;
    if (serviceId != null) _activeServiceId = serviceId;
    if (startDate != null) _activeStartDate = startDate;
    if (endDate != null) _activeEndDate = endDate;

    emit(BookingFunnelLoading(
      filter: _activeFilter,
      customDate: _customSelectedDate,
    ));

    final result = await getBookingFunnelStatsUseCase(
      startDate: _activeStartDate,
      endDate: _activeEndDate,
      serviceId: _activeServiceId,
    );

    result.fold(
      (failure) {
        debugPrint('❌ [BookingFunnelCubit] Failed to load funnel: ${failure.message}');
        emit(BookingFunnelError(
          failure.message,
          filter: _activeFilter,
          customDate: _customSelectedDate,
        ));
      },
      (funnel) {
        debugPrint('✅ [BookingFunnelCubit] Loaded funnel: started=${funnel.summary.totalStarted}, '
            'completed=${funnel.summary.totalCompleted}, '
            'conversion=${funnel.summary.overallConversionRate}%');
        if (funnel.summary.totalStarted == 0 && funnel.steps.every((s) => s.count == 0)) {
          emit(BookingFunnelEmpty(
            filter: _activeFilter,
            customDate: _customSelectedDate,
          ));
        } else {
          emit(BookingFunnelLoaded(
            funnel,
            filter: _activeFilter,
            customDate: _customSelectedDate,
          ));
        }
      },
    );
  }
}
