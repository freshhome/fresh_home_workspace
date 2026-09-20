import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_booking_funnel_stats_use_case.dart';
import 'booking_funnel_state.dart';

class BookingFunnelCubit extends Cubit<BookingFunnelState> {
  final GetBookingFunnelStatsUseCase getBookingFunnelStatsUseCase;

  BookingFunnelCubit({required this.getBookingFunnelStatsUseCase})
      : super(const BookingFunnelInitial());

  Future<void> loadFunnelStats({
    DateTime? startDate,
    DateTime? endDate,
    String? serviceId,
  }) async {
    debugPrint('📊 [BookingFunnelCubit] Triggered loadFunnelStats()...');
    emit(const BookingFunnelLoading());

    final result = await getBookingFunnelStatsUseCase(
      startDate: startDate,
      endDate: endDate,
      serviceId: serviceId,
    );

    result.fold(
      (failure) {
        debugPrint('❌ [BookingFunnelCubit] Failed to load funnel: ${failure.message}');
        emit(BookingFunnelError(failure.message));
      },
      (funnel) {
        debugPrint('✅ [BookingFunnelCubit] Loaded funnel: started=${funnel.summary.totalStarted}, '
            'completed=${funnel.summary.totalCompleted}, '
            'conversion=${funnel.summary.overallConversionRate}%');
        if (funnel.summary.totalStarted == 0 && funnel.steps.every((s) => s.count == 0)) {
          emit(const BookingFunnelEmpty());
        } else {
          emit(BookingFunnelLoaded(funnel));
        }
      },
    );
  }
}
