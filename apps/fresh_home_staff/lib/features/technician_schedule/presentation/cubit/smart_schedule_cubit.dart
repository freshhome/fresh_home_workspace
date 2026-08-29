import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared/domain/technician/repositories/technician_repository.dart';
import 'smart_schedule_state.dart';

class SmartScheduleCubit extends Cubit<SmartScheduleState> {
  final TechnicianRepository _repository;

  SmartScheduleCubit(this._repository) : super(SmartScheduleInitial());

  void safeEmit(SmartScheduleState state) {
    if (!isClosed) {
      emit(state);
    }
  }

  Future<void> loadSchedule(
    String technicianId, {
    DateTime? month,
  }) async {
    final now = DateTime.now();
    final targetMonth = month ?? DateTime(now.year, now.month, 1);
    final targetSelectedDate = (targetMonth.year == now.year && targetMonth.month == now.month)
        ? DateTime(now.year, now.month, now.day)
        : targetMonth;

    safeEmit(SmartScheduleLoading());

    // Single Batch Query for the entire month
    final firstDayOfMonth = DateTime(targetMonth.year, targetMonth.month, 1);
    final lastDayOfMonth = DateTime(targetMonth.year, targetMonth.month + 1, 0);

    final result = await _repository.getSmartSchedule(
      technicianId,
      startDate: firstDayOfMonth,
      endDate: lastDayOfMonth,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async {
        safeEmit(SmartScheduleError(failure.message));
      },
      (forecast) async {
        safeEmit(SmartScheduleLoaded(
          schedule: forecast.schedule,
          generalRecommendation: forecast.generalRecommendation,
          selectedDate: targetSelectedDate,
          currentMonth: targetMonth,
        ));
        await loadDailyBreakdown(technicianId: technicianId, date: targetSelectedDate);
      },
    );
  }

  void selectDate(String technicianId, DateTime date) {
    if (isClosed) return;
    final currentState = state;
    if (currentState is SmartScheduleLoaded) {
      // Instant selection from In-Memory state with 0 reads
      safeEmit(currentState.copyWith(selectedDate: date));
      loadDailyBreakdown(technicianId: technicianId, date: date);
    }
  }

  void changeMonth(String technicianId, int offset) {
    if (isClosed) return;
    final now = DateTime.now();
    final minMonth = DateTime(now.year, now.month - 1, 1);
    final maxMonth = DateTime(now.year, now.month + 1, 1);

    DateTime currentMonthDate;
    final currentState = state;
    if (currentState is SmartScheduleLoaded) {
      currentMonthDate = currentState.currentMonth;
    } else {
      currentMonthDate = DateTime(now.year, now.month, 1);
    }

    final targetMonth = DateTime(
      currentMonthDate.year,
      currentMonthDate.month + offset,
      1,
    );

    // Strictly limit navigation window to [Past Month, Current Month, Next Month]
    if (targetMonth.isBefore(minMonth) || targetMonth.isAfter(maxMonth)) {
      return;
    }

    loadSchedule(technicianId, month: targetMonth);
  }

  Future<void> loadDailyBreakdown({
    required String technicianId,
    required DateTime date,
  }) async {
    if (isClosed) return;
    final currentState = state;
    if (currentState is SmartScheduleLoaded) {
      final result = await _repository.getDailyPoolBreakdown(
        technicianId: technicianId,
        date: date,
      );

      if (isClosed) return;

      result.fold(
        (failure) => safeEmit(SmartScheduleError(failure.message)),
        (breakdown) => safeEmit(currentState.copyWith(poolBreakdown: breakdown)),
      );
    }
  }

  Future<void> updatePoolCapacity({
    required String technicianId,
    required String poolId,
    required DateTime date,
    required int newCapacity,
    String? slotMask,
  }) async {
    final result = await _repository.updateDailyCapacity(
      technicianId: technicianId,
      date: date,
      newCapacity: newCapacity,
      isBlocked: false,
      poolId: poolId,
      reason: 'Slot update by technician',
      slotMask: slotMask,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async => safeEmit(SmartScheduleError(failure.message)),
      (_) async {
        if (isClosed) return;
        DateTime? currentMonth;
        if (state is SmartScheduleLoaded) {
          currentMonth = (state as SmartScheduleLoaded).currentMonth;
        }
        await loadSchedule(technicianId, month: currentMonth);
        if (isClosed) return;
        await loadDailyBreakdown(technicianId: technicianId, date: date);
      },
    );
  }

  Future<void> updateDailyCapacity({
    required String technicianId,
    required DateTime date,
    required int newCapacity,
    required bool isBlocked,
    String? reason,
    String? slotMask,
  }) async {
    final result = await _repository.updateDailyCapacity(
      technicianId: technicianId,
      date: date,
      newCapacity: newCapacity,
      isBlocked: isBlocked,
      reason: reason,
      slotMask: slotMask,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async => safeEmit(SmartScheduleError(failure.message)),
      (_) async {
        if (isClosed) return;
        DateTime? currentMonth;
        if (state is SmartScheduleLoaded) {
          currentMonth = (state as SmartScheduleLoaded).currentMonth;
        }
        await loadSchedule(technicianId, month: currentMonth);
        if (isClosed) return;
        await loadDailyBreakdown(technicianId: technicianId, date: date);
      },
    );
  }

  Future<void> resetDailyCapacity({
    required String technicianId,
    required DateTime date,
  }) async {
    final result = await _repository.resetDailyCapacity(
      technicianId: technicianId,
      date: date,
    );

    if (isClosed) return;

    await result.fold(
      (failure) async => safeEmit(SmartScheduleError(failure.message)),
      (_) async {
        if (isClosed) return;
        DateTime? currentMonth;
        if (state is SmartScheduleLoaded) {
          currentMonth = (state as SmartScheduleLoaded).currentMonth;
        }
        await loadSchedule(technicianId, month: currentMonth);
      },
    );
  }

  Future<bool> reassignAndBlockCapacity({
    required String technicianId,
    required DateTime date,
    String? poolId,
    int? slotIndex,
  }) async {
    final result = await _repository.reassignAndBlockCapacity(
      technicianId: technicianId,
      date: date,
      poolId: poolId,
      slotIndex: slotIndex,
    );

    if (isClosed) return false;

    return result.fold(
      (failure) {
        safeEmit(SmartScheduleError(failure.message));
        return false;
      },
      (success) async {
        if (success && !isClosed) {
          DateTime? currentMonth;
          if (state is SmartScheduleLoaded) {
            currentMonth = (state as SmartScheduleLoaded).currentMonth;
          }
          await loadSchedule(technicianId, month: currentMonth);
          if (!isClosed) {
            await loadDailyBreakdown(technicianId: technicianId, date: date);
          }
        }
        return success;
      },
    );
  }
}
